class AddCustomFooterHtmlToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_column :blogs, :custom_footer_html, :text
  end
end
