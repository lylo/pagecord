class AddShowMetricsToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_column :blogs, :show_metrics, :boolean, default: true, null: false
  end
end
