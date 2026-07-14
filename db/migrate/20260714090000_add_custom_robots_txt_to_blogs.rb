class AddCustomRobotsTxtToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_column :blogs, :custom_robots_txt, :text
  end
end
