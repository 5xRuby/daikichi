class CreateOvertimePays < ActiveRecord::Migration[5.0]
  def change
    create_table :overtime_pays do |t|
      t.references :overtime, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :hour, null: false
      t.text :remark

      t.timestamps
    end
  end
end
