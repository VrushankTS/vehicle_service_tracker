class AddVehicleTypeToVehicles < ActiveRecord::Migration[8.1]
  def change
    add_reference :vehicles, :vehicle_type, foreign_key: true
  end
end
