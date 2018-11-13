class AddTypeToOvertimes < ActiveRecord::Migration[5.0]
  def change
    add_column :overtimes, :compensatory_type, :integer, default: 0
    add_index :overtimes, :compensatory_type
  end
end
