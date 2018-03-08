class CreateOvertimes < ActiveRecord::Migration[5.0]
  def change
    create_table :overtimes do |t|
      t.integer :user_id
      t.integer :hours, default: 0
      t.datetime :start_time
      t.datetime :end_time
      t.text :description, null: true
      t.string :status, default: 'pending'
      t.datetime :sign_date, null: true
      t.datetime :deleted_at, null: true

      t.timestamps
    end
  end
end
