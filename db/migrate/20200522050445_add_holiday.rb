class AddHoliday < ActiveRecord::Migration[5.2]
  def change
    create_table :holidays do |t|
      t.datetime :date

      t.timestamps
    end
  end
end
