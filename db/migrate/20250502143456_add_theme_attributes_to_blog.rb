class AddThemeAttributesToBlog < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :theme, :string, null: false, default: "base"
    add_column :blogs, :font, :string, null: false, default: "sans"
    add_column :blogs, :width, :string, null: false, default: "standard"
  end
end
