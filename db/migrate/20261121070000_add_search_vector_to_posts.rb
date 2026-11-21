class AddSearchVectorToPosts < ActiveRecord::Migration[8.2]
  def change
    add_column :posts, :search_vector, :tsvector
  end
end
