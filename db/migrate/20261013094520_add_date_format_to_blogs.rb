class AddDateFormatToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_column :blogs, :date_format, :string
  end
end
