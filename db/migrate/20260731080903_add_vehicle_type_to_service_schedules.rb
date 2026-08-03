class AddVehicleTypeToServiceSchedules < ActiveRecord::Migration[8.1]
  def change
    add_reference :service_schedules, :vehicle_type, foreign_key: true
  end
end
