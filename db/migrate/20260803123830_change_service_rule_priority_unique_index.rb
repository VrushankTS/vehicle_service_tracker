class ChangeServiceRulePriorityUniqueIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :service_rules, name: "index_service_rules_on_vehicle_type_id_and_priority"
    add_index :service_rules, 
              [:vehicle_type_id, :strategy_domain, :priority], 
              unique: true,
              name: "idx_service_rules_vehicle_type_domain_priority"
  end
end
