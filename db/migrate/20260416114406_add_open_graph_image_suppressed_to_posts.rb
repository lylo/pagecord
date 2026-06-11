class AddOpenGraphImageSuppressedToPosts < ActiveRecord::Migration[8.2]
  def change
    add_column :posts, :open_graph_image_suppressed, :boolean, default: false, null: false
  end
end
