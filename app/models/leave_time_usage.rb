# frozen_string_literal: true

class LeaveTimeUsage < ApplicationRecord
  belongs_to :leave_application
  belongs_to :leave_time

  after_create :transfer_leave_time_hours

  private

  def transfer_leave_time_hours
    self.leave_time.reload.lock_hours!(self.used_hours)
  end
end
