class DropAndRecreateOpenGraphImagesWithPolymorphism < ActiveRecord::Migration[8.1]
  def change
    # Drop existing table (data is redundant/will be regenerated)
    drop_table :open_graph_images, if_exists: true

    # Recreate with polymorphic association
    create_table :open_graph_images do |t|
      t.references :imageable, polymorphic: true, null: false, index: true
      t.timestamps
    end
  end
end
