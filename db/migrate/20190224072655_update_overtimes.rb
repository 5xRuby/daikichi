# frozen_string_literal: true
class UpdateOvertimes < ActiveRecord::Migration[5.0]
  def change
    add_reference :overtimes, :manager, index: true
    add_column :overtimes, :sign_date, :datetime
    add_column :overtimes, :deleted_at, :datetime
    add_column :overtimes, :comment, :text
    add_column :overtimes, :compensatory_type, :integer, default: 0

    add_index :overtimes, :user_id
    add_index :overtimes, :compensatory_type
  end
end
