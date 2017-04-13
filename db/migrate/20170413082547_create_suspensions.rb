# frozon_string_literal: true
class CreateSuspensions < ActiveRecord::Migration[5.0]
  def change
    create_table :suspensions do |t|
      t.integer :user_id
      t.date :start_date
      t.date :end_date
      t.text :remark

      t.timestamps
    end
  end
end
