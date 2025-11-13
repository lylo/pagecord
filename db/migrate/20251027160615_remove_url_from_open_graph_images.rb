class RemoveUrlFromOpenGraphImages < ActiveRecord::Migration[8.1]
  def change
    remove_column :open_graph_images, :url, :string
  end
end
