# frozen_string_literal: true
class CreateLeaveApplicationLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :leave_application_logs do |t|
      t.integer :leave_application_id
      t.integer :general_hours, default: 0
      t.integer :annual_hours, default: 0
      t.boolean :returning?, default: false

      t.timestamps
    end
  end
end
