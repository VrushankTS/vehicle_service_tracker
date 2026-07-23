class CreateOdometerLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :odometer_logs do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.bigint :logged_by, null: false
      t.integer :reading, null: false
      t.datetime :recorded_at, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
    end

    add_foreign_key :odometer_logs, :users, column: :logged_by
    add_index :odometer_logs, :logged_by
  end
end