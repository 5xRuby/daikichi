class AddRemarkToLeaveTime < ActiveRecord::Migration[5.0]
  def change
    add_column :leave_times, :remark, :text
  end
end
