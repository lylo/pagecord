class AddHtmlFlagToPost < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :html, :boolean, null: false
  end
end
