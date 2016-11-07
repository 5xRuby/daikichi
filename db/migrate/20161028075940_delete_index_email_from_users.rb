# frozen_string_literal: true
class DeleteIndexEmailFromUsers < ActiveRecord::Migration[5.0]
  def change
    remove_index :users, :email
  end
end
