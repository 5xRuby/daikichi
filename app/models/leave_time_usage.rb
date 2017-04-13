class LeaveTimeUsage < ApplicationRecord
  belongs_to :leave_application
  belongs_to :leave_time
end
