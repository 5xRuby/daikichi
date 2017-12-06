# frozen_string_literal: true
require 'csv'

namespace :import_data do
  desc "create default admin user"
  task default_admin: :environment do
    User.find_or_create_by!(login_name: Settings.admin_user.login_name) do |user|
      user.email = Settings.admin_user.email
      user.name = Settings.admin_user.name
      user.role = Settings.admin_user.role
      user.join_date = Settings.admin_user.join_date
      user.password = Settings.admin_user.password
      user.password_confirmation = Settings.admin_user.password
    end
  end

  # TODO: temporary use for development only
  desc "user data"
  task users: :environment do
    CSV.foreach(ENV['PATH_FOR_USERS'], headers: true, header_converters: :symbol, converters: :date) do |row|
      temp_password = SecureRandom.hex(12)
      user = User.new(
        login_name: row[:username],
        name: row[:fullname],
        email: row[:email],
        role: row[:role],
        join_date: row[:join_date],
        leave_date: row[:leave_date],
        password: temp_password,
        password_confirmation: temp_password
      )
      puts "Import Failed: L#{$.} \n\t #{row.to_h} \n\t #{user.errors.messages} \n" unless user.save
    end
  end

  # TODO: No longer a valid tasks, needs to be removed
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

  desc 'Leave Time import from csv'
  task leave_times: :environment do
    CSV.foreach(ENV['PATH_FOR_LEAVE_TIMES'], headers: true, header_converters: :symbol) do |row|
      user = User.find_by(login_name: row[:login_name])
      puts row.to_h unless user
      leave_time = LeaveTime.new(
        user: user,
        leave_type: row[:leave_type],
        quota: row[:quota],
        usable_hours: row[:quota],
        used_hours: 0,
        effective_date:  row[:effective_date],
        expiration_date: row[:expiration_date]
      )
      puts "Import Failed: L#{$.} \n\t #{row.to_h} \n\t #{leave_time.errors.messages} \n" unless leave_time.save
    end
  end
end
