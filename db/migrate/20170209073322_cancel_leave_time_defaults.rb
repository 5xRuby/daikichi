class CancelLeaveTimeDefaults < ActiveRecord::Migration[5.0]
  def down
    change_column_default :leave_times, :quota, 0
    change_column_default :leave_times, :usable_hours, 0
  end
  def up
    change_column_default :leave_times, :quota, nil
    change_column_default :leave_times, :usable_hours, nil
  end
end
