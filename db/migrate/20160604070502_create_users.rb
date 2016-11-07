# frozen_string_literal: true
class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :name, null: false, default: ""
      t.string :login_name, null: false, unique: true
      t.string :role, default: "pending"
      t.date :join_date
      t.date :leave_date

      t.timestamps
    end
  end
end
