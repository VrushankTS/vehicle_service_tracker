class AddOdometerReadingColumnToVehicles < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicles, :odometer_reading, :integer
  end
end
