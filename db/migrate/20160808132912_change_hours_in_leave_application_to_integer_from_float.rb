# frozen_string_literal: true
class ChangeHoursInLeaveApplicationToIntegerFromFloat < ActiveRecord::Migration[5.0]
  def change
    change_column :leave_applications, :hours, :integer
  end
end
