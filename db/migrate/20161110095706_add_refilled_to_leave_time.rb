# frozen_string_literal: true
class AddRefilledToLeaveTime < ActiveRecord::Migration[5.0]
  def change
    add_column :leave_times, :refilled, :boolean, default: false
  end
end
