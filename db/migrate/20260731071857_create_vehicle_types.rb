class CreateVehicleTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicle_types do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_index :vehicle_types, :code, unique: true
    add_index :vehicle_types, :name, unique: true
  end
end
