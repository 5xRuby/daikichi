class AddRefillToLeaveTime < ActiveRecord::Migration[5.0]
  def change
    add_column :leave_times, :refill?, :boolean, default: false
  end
end
