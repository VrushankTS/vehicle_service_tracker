class CreateServiceRules < ActiveRecord::Migration[8.1]
  def change
    create_table :service_rules do |t|
      t.references :vehicle_type, null: false, foreign_key: true
      t.references :service_type, foreign_key: true

      t.string :name, null: false
      t.json :condition
      t.integer :priority, null: false
      t.string :strategy_domain, null: false
      t.string :strategy_key, null: false
      t.json :rule_config
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :service_rules, [:vehicle_type_id, :priority], unique: true

    add_index :service_rules,
              [:vehicle_type_id, :strategy_domain, :service_type_id],
              unique: true,
              where: "condition IS NULL",
              name: "idx_one_fallback_per_type_domain_service_type"
  end
end