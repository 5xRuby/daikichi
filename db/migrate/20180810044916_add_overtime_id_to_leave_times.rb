class AddOvertimeIdToLeaveTimes < ActiveRecord::Migration[5.0]
  def change
    add_reference :leave_times, :overtime, foreign_key: true
  end
end
