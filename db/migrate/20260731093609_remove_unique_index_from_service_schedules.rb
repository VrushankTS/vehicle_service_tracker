class RemoveUniqueIndexFromServiceSchedules < ActiveRecord::Migration[8.1]
  def change
    remove_index :service_schedules, column: [:bike_model_id, :service_type_id]
  end
end
