class AddFormatToBlogExports < ActiveRecord::Migration[8.1]
  def change
    add_column :blog_exports, :format, :integer, default: 0, null: false
  end
end
