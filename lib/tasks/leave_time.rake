namespace :leave_time do

  desc "initialize employee annual leave time"
  task :init, [:year] => [:environment] do |t, args|
    year = args[:year].nil? ? Time.zone.today.year : args[:year].to_i
    User.employees.each do |user|
      LeaveTime::BASIC_TYPES.each do |leave_type|
        leave_time = user.leave_times.build(year: year, leave_type: leave_type)
        leave_time.init_quota
      end
    end
  end

end
