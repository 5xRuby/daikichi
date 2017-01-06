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
    YAML.load_file("lib/tasks/leaves.yml").each do |leave|
      data = leave.split(",")
      attributes = {
        leave_type: data[1],
        start_time: Time.parse(data[2]),
        end_time: Time.parse(data[3]),
        description: "系統匯入"
      }

      leave_id = User.find_by(name: data[0]).leave_applications.create!(attributes).id
      manager = User.find_by(name: "趙子皓")
      LeaveApplication.find(leave_id).approve!(manager)

      puts "#{data[0]}匯入#{data[1]}假單"
    end
  end

  # 匯入過去補修時數
  desc "users' bonus leave times"
  task bonus_leave_times: :environment do
    YAML.load_file("lib/tasks/bonus_leave_times.yml").each do |bonus_leave_time|
      data = bonus_leave_time.split(",")
      user_id = User.find_by(name: data[0]).id
      attributes = {
        quota: data[1],
        usable_hours: data[1]
      }
      LeaveTime.personal(user_id, "bonus", 2016).update!(attributes)
      puts "#{data[0]} 補修增加 #{data[1]} 時數"
    end
  end
end
