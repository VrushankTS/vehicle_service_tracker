class CreateAlerts < ActiveRecord::Migration[8.1]
  def change
    create_table :alerts do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :service_type, null: false, foreign_key: true

      t.string :alert_type, null: false
      t.date :due_date
      t.integer :due_odometer

      t.string :status, null: false, default: "pending"
      t.integer :last_notified_stage, null: false, default: 0

      t.datetime :sent_at

      t.timestamps
    end
  end
end