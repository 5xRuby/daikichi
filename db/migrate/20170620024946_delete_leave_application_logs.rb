class DeleteLeaveApplicationLogs < ActiveRecord::Migration[5.0]
  def change
    remove_index :leave_application_logs, :leave_application_uuid

    drop_table :leave_application_logs do |t|
      t.string :leave_application_uuid
      t.integer :amount, default: 0
      t.boolean :returning?, default: false

      t.timestamps
    end
  end
end
