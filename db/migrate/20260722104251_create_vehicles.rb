class CreateVehicles < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicles do |t|
      t.references :bike_model, null: false, foreign_key: true
      t.string :registration_number, null: false
      t.date :purchase_date, null: false

      t.timestamps
    end

    add_index :vehicles, :registration_number, unique: true
  end
end
