class AddCategoryScoresToContentModerations < ActiveRecord::Migration[8.2]
  def change
    add_column :content_moderations, :category_scores, :jsonb, default: {}
  end
end
