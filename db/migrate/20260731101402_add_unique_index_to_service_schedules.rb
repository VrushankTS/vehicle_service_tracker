class AddUniqueIndexToServiceSchedules < ActiveRecord::Migration[8.1]
  def change
    add_index :service_schedules, [:vehicle_type_id, :bike_model_id, :service_type_id], unique: true
  end
end
