# frozen_string_literal: true
namespace :import_data do
  desc "create default admin user"
  task default_admin: :environment do
    User.find_or_create_by!(login_name: Settings.admin_user.login_name) do |user|
      user.email = Settings.admin_user.email
      user.name = Settings.admin_user.name
      user.role = Settings.admin_user.role
      user.password = Settings.admin_user.password
      user.password_confirmation = Settings.admin_user.password
    end
  end

  # TODO: temporary use for development only
  desc "user data"
  task users: :environment do
    YAML.load_file("lib/tasks/users.yml").each do |user|
      data = user.split(",")
      attributes = {
        login_name: data[0],
        name: data[1],
        email: data[2],
        role: data[3],
        password: Settings.admin_user.password,
        password_confirmation: Settings.admin_user.password,
        join_date: data[4]
      }
      User.create(attributes)
    end
  end

  # 匯入過去所有請的假
  desc "users' leaves"
  task leaves: :environment do
    puts "Usage: file=path_to_file approver=approver_name [description=description] rake import_data:leaves"
    puts "csv file format in each row (line):"
    puts "name,type,start_,expiration_date"
    description = ENV['description'] || 'from rake import_data:leaves'
    interactive = ENV['interactive'].present?

    approver = User.find_by(name: ENV['approver'])
    raise "User '#{ENV['approver']}' not found" if approver.nil?

    require 'csv'
    puts "Working..."
    CSV.foreach(ENV['file'] || "tmp/leaves.csv") do |row|
      begin
        user = User.find_by(name: row[0])
        raise "User '#{row[0]}' not found" if user.nil?
        #raise 'ha' if user.name != j
        la = LeaveApplication.new(user: user, leave_type: row[1], start_time: row[2], end_time: row[3], description: description, import_mode: true)
        while interactive and not la.valid?
          puts "LeaveApplication not valid:"
          p la
          puts "User:"
          p user
          puts "Errors:"
          p la.errors
          puts "\nPlease input a hash to reasign attrs: "
          la.assign_attributes(eval(STDIN.gets))
        end
        la.approve! approver
        puts ">> OK!" if la.save!
      rescue => e
        puts "!! Error:"
        pp e
        puts "...on row:"
        pp row
      end
    end
  end

  # 匯入過去補修時數
  desc "leave times (quota)"
  task leave_times: :environment do
    puts "Usage: file=path_to_file type=leave_type rake import_data:leave_times"
    puts "csv file format in each row (line):"
    puts "name,quota,effective_date,expiration_date"
    leave_type = ENV['type'] || 'bonus'
    
    require 'csv'
    puts "Working..."
    CSV.foreach(ENV['file'] || "tmp/leave_times.csv") do |row|
      begin
        user = User.find_by(name: row[0])
        raise "User '#{row[0]}' not found" if user.nil?
        lt = LeaveTime.new(user: user, quota: row[1], leave_type: leave_type, effective_date: row[2], expiration_date: row[3])
        pp lt
        puts ">> OK!" if lt.save!
      rescue => e
        puts "!! Error:"
        pp e
        puts "...on row:"
        pp row
      end
    end
  end
end
