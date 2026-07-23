class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :service_record, null: false, foreign_key: true

      t.bigint :uploaded_by, null: false

      t.string :invoice_number
      t.bigint :amount, null: false
      t.string :file_url
      t.date :issued_at

      t.timestamps
    end

    add_foreign_key :invoices, :users, column: :uploaded_by
    add_index :invoices, :uploaded_by
    add_index :invoices, :invoice_number, unique: true
  end
end