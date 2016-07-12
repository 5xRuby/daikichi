namespace :import_data do

  #TODO temporary use for development only
  desc 'user data'
  task users: :environment do
    YAML.load_file('lib/tasks/users.yml').each do |user|
      data = user.split(',')
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
