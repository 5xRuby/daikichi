class CreateOvertimes < ActiveRecord::Migration[5.0]
  def change
    create_table :overtimes do |t|
      t.references :user, foreign_key: true
      t.integer  :hours,         default: 0
      t.datetime :start_time
      t.datetime :end_time
      t.text     :description
      t.string   :status,        default: "pending"
      t.datetime :sign_date
      t.datetime :deleted_at
      t.text     :comment

      t.timestamps
    end
    add_reference :overtimes, :manager, index: true
  end
end