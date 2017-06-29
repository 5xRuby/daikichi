require 'rake'

Rails.app_class.load_tasks

class CreateLeaveTime
  def perform
    Rake::Task['import:leave_time'].invoke
  end
end

Crono.perform(CreateLeaveTime).every 1.day, at: { hour: 2, min: 0 }
