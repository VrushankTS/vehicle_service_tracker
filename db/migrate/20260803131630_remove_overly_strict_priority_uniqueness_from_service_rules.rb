class RemoveOverlyStrictPriorityUniquenessFromServiceRules < ActiveRecord::Migration[8.1]
  def change
    remove_index :service_rules, name: "idx_service_rules_vehicle_type_domain_priority"
  end
end
