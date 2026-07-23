class CreateServiceSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :service_schedules do |t|
      t.references :bike_model, null: false, foreign_key: true
      t.references :service_type, null: false, foreign_key: true
      t.bigint :interval_km
      t.integer :interval_months

      t.timestamps
    end

    add_index :service_schedules, [:bike_model_id, :service_type_id], unique: true
  end
end