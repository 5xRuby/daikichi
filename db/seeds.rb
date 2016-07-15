# frozen_string_literal: true
# default admin user
User.find_or_create_by!(login_name: Settings.admin_user.login_name) do |user|
  user.email = Settings.admin_user.email
  user.name = Settings.admin_user.name
  user.role = Settings.admin_user.role
  user.password = Settings.admin_user.password
  user.password_confirmation = Settings.admin_user.password
end
