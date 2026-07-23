class CreateInvoiceItems < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :description, null: false
      t.string :item_type, null: false
      t.bigint :amount, null: false

      t.timestamps
    end
  end
end