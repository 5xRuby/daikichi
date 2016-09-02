class ChangeHoursInLeaveApplicationToFloatFromInteger < ActiveRecord::Migration[5.0]
  def change
    change_column :leave_applications, :hours, :float
  end
end
