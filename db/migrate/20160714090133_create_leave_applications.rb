# frozen_string_literal: true
class CreateLeaveApplications < ActiveRecord::Migration[5.0]
  def change
    create_table :leave_applications do |t|
      t.integer :user_id
      t.string :leave_type
      t.integer :hours, default: 0
      t.datetime :start_time
      t.datetime :end_time
      t.text :description, null: true
      t.string :status, default: 'pending'
      t.datetime :sign_date, null: true
      t.datetime :deleted_at, null: true

      t.timestamps
    end

    add_reference :leave_applications, :manager, index: true
  end
end
