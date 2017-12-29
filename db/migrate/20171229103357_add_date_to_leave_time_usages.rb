class AddDateToLeaveTimeUsages < ActiveRecord::Migration[5.0]
  def change
    add_column :leave_time_usages, :date, :date
  end
end
