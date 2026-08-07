class ChangeReadingColumnNullInVehicles < ActiveRecord::Migration[8.1]
  def change
    change_column_null :vehicles, :odometer_reading, false
  end
end
