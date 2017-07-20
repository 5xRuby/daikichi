# frozen_string_literal: true
class AddValidRangeForLeaveTime < ActiveRecord::Migration[5.0]
  def change
    remove_column :leave_times, :year, :integer
    add_column :leave_times, :effective_date,  :date
    add_column :leave_times, :expiration_date, :date

    LeaveTime.all.each do |leave_time|
      leave_time.update(
        effective_date:  Date.new(2016, 1,  1),
        expiration_date: Date.new(2016, 12, 31)
      )
    end

    reversible do |dir|
      dir.up do
        execute 'alter table leave_times alter column effective_date  set default now()'
        execute 'alter table leave_times alter column expiration_date set default now()'

        change_column :leave_times, :effective_date,   :date, null: false
        change_column :leave_times, :expiration_date,  :date, null: false
        change_column :leave_times, :user_id, :integer, null: false
      end
      dir.down do
        change_column :leave_times, :user_id, :integer, null: true
      end
    end
  end
end
