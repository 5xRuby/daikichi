class CreateOvertimes < ActiveRecord::Migration[5.0]
  def change
    create_table :overtimes do |t|
      t.integer :user_id
      t.integer :hours, default: 0
      t.datetime :start_time
      t.datetime :end_time
      t.text :description, null: true
      t.string :status, default: 'pending'

      t.timestamps
    end
  end
end
