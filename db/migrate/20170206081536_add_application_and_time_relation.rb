# frozen_string_literal: true
class AddApplicationAndTimeRelation < ActiveRecord::Migration[5.0]
  def change
    add_column :leave_applications, :leave_time_id, :integer
  end
end
