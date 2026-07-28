class AddDismissedByToAlerts < ActiveRecord::Migration[8.1]
  def change
    add_reference :alerts, :dismissed_by, foreign_key: { to_table: :users }
  end
end
