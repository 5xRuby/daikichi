class AddCommentColumnForLeaveApplication < ActiveRecord::Migration[5.0]
  def change
    add_column :leave_applications, :comment, :text
  end
end
