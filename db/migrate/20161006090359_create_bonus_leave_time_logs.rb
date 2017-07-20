# frozen_string_literal: true
class CreateBonusLeaveTimeLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :bonus_leave_time_logs do |t|
      t.integer :user_id
      t.integer :manager_id
      t.datetime :authorize_date
      t.integer :hours, default: 0
      t.text :description
      t.timestamps
    end
  end
end
