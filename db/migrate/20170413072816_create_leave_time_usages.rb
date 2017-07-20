# frozen_string_literal: true
class CreateLeaveTimeUsages < ActiveRecord::Migration[5.0]
  def change
    create_table :leave_time_usages do |t|
      t.references :leave_application, foreign_key: true
      t.references :leave_time, foreign_key: true
      t.integer :used_hours

      t.timestamps
    end

    add_column :leave_times, :locked_hours, :integer
  end
end
