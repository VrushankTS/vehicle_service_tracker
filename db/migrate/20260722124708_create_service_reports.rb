class CreateServiceReports < ActiveRecord::Migration[8.1]
  def change
    create_table :service_reports do |t|
      t.references :vehicle, null: false, foreign_key: true

      t.references :service_record, null: false, foreign_key: true, index: { unique: true }

      t.bigint :uploaded_by, null: false
      t.datetime :uploaded_at, default: -> { "CURRENT_TIMESTAMP" }
      t.string :file_url

      t.timestamps
    end

    add_foreign_key :service_reports, :users, column: :uploaded_by
    add_index :service_reports, :uploaded_by
  end
end