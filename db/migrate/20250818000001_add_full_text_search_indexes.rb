class AddFullTextSearchIndexes < ActiveRecord::Migration[8.1]
  def change
    # Enable pg_trgm extension for trigram search
    enable_extension "pg_trgm"

    # GIN index on action_text_rich_texts body for content search
    add_index :action_text_rich_texts, :body, using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_action_text_rich_texts_on_body_gin"

    # GIN index on posts title
    add_index :posts, :title, using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_posts_on_title_gin"
  end
end
