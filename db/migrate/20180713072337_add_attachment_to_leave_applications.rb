class AddAttachmentToLeaveApplications < ActiveRecord::Migration[5.0]
  def change
    add_column :leave_applications, :attachment, :string
  end
end
