# frozen_string_literal: true
class DeleteColumnOfLeaveApplication < ActiveRecord::Migration[5.0]
  def change
  	remove_column :leave_applications, :uuid
  end
end
