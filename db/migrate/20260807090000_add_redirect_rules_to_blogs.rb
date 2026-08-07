class AddRedirectRulesToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_column :blogs, :redirect_rules, :text
  end
end
