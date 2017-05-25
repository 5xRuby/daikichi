# frozen_string_literal: true
class LeaveTimeUsage < ApplicationRecord
  belongs_to :leave_application
  belongs_to :leave_time

  after_create :lock_leave_time_hours

  private

  def lock_leave_time_hours
    leave_time = LeaveTime.find(self.leave_time_id)
    leave_time.lock_hours!(self.used_hours)
  end
end
