# frozen_string_literal: true
class LeaveTimeUsage < ApplicationRecord
  belongs_to :leave_application
  belongs_to :leave_time

  after_create :transfer_leave_time_hours

  private

  def transfer_leave_time_hours
    if self.reload.leave_time.special_type?
      self.leave_time.direct_use_hours!(self.used_hours)
    else
      self.leave_time.lock_hours!(self.used_hours)
    end
  end
end
