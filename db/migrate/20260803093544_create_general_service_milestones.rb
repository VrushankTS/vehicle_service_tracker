class CreateGeneralServiceMilestones < ActiveRecord::Migration[8.1]
  def change
    create_table :general_service_milestones do |t|
      t.references :service_rule, null: false, foreign_key: true
      t.integer :sequence, null: false
      t.integer :interval_km, null: false
      t.integer :interval_months, null: false

      t.timestamps
    end

    add_index :general_service_milestones, [:service_rule_id, :sequence], unique: true
  end
end
