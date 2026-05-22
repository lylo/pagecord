class DropOpenGraphImages < ActiveRecord::Migration[8.2]
  def change
    drop_table :open_graph_images do |t|
      t.references :post, null: false, foreign_key: true
      t.string :url, null: false
      t.timestamps
    end
  end
end
