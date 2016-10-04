class AddUuidToLeaveApplication < ActiveRecord::Migration[5.0]
  def change
    add_column :leave_applications, :uuid, :string, null: false
    add_index :leave_applications, :uuid, unique: true
  end
end
