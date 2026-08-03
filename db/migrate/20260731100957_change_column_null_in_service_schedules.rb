class ChangeColumnNullInServiceSchedules < ActiveRecord::Migration[8.1]
  def change
    change_column_null :service_schedules, :vehicle_type_id, false
  end
end
