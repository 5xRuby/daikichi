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
end
