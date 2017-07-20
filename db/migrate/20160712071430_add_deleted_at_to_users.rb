# frozen_string_literal: true
class AddDeletedAtToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :deleted_at, :datetime
    add_index :users, :deleted_at
  end
end
