# frozen_string_literal: true
class ChangeColumnsOfLeaveApplicationLogs < ActiveRecord::Migration[5.0]
  def change
    remove_column :leave_application_logs, :general_hours
    remove_column :leave_application_logs, :annual_hours
    add_column :leave_application_logs, :amount, :integer, default: 0
  end
end
