class CreateOpenGraphImages < ActiveRecord::Migration[7.2]
  def change
    create_table :open_graph_images do |t|
      t.string :url, null: false
      t.references :post, null: false, foreign_key: true

      t.timestamps
    end
  end
end
