class AddRawContentToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :raw_content, :text
  end
end
