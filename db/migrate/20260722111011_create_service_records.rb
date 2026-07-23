class CreateServiceRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :service_records do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :service_type, null: false, foreign_key: true

      t.bigint :completed_by, null: false

      t.integer :odometer_at_service, null: false
      t.datetime :serviced_at, null: false, default: -> { "CURRENT_TIMESTAMP" }

      t.integer :next_due_odometer
      t.date :next_due_date

      t.text :notes

      t.timestamps
    end

    add_foreign_key :service_records, :users, column: :completed_by
    add_index :service_records, :completed_by
  end
end