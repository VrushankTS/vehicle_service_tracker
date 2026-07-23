class CreateBikeModels < ActiveRecord::Migration[8.1]
  def change
    create_table :bike_models do |t|
      t.string :brand, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_index :bike_models, [:brand, :name], unique: true
  end
end
