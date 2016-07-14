class CreateLeaveTimes < ActiveRecord::Migration[5.0]
  def change
    create_table :leave_times do |t|
      t.integer :user_id
      t.integer :year, index: true
      t.string :leave_type
      t.integer :quota, default: 0
      t.integer :usable_hours, default: 0
      t.integer :used_hours, default: 0

      t.timestamps
    end
  end
end
