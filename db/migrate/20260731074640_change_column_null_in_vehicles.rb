class ChangeColumnNullInVehicles < ActiveRecord::Migration[8.1]
  def change
    change_column_null :vehicles, :vehicle_type_id, false
  end
end
