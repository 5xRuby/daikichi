# frozen_string_literal: true
require 'csv'

namespace :import_data do
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
