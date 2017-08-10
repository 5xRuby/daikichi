class UpdateLeaveApplicationLeaveType < ActiveRecord::Migration[5.0]
  def self.up
    LeaveApplication.where(leave_type: [:annual, :bonus]).each do |q|
      q.update!(leave_type: :personal)
    end
  end

  def self.down
  end
end
