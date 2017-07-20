# frozen_string_literal: true
class CreateLeaveHoursByDates < ActiveRecord::Migration[5.0]
  def change
    create_table :leave_hours_by_dates do |t|
      t.references :leave_application, foreign_key: true
      t.date :date
      t.integer :hours

      t.timestamps
    end
  end
end
