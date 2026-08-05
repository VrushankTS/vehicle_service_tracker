class RemoveServiceTypeFromServiceRules < ActiveRecord::Migration[8.1]
  def change
    remove_reference :service_rules, :service_type, foreign_key: true
  end
end
