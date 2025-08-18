class RemoveRedundantSearchIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # Remove redundant tsvector indexes (trigram indexes are more versatile)
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_posts_on_title_tsvector"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_action_text_rich_texts_on_body_tsvector"

    # Remove duplicate GIN indexes from AddFullTextSearchIndexes migration
    remove_index :posts, name: "index_posts_on_title_gin", if_exists: true
    remove_index :action_text_rich_texts, name: "index_action_text_rich_texts_on_body_gin", if_exists: true
  end

  def down
    # Recreate the removed indexes if needed
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_posts_on_title_tsvector
      ON posts USING gin(to_tsvector('simple', coalesce(title, '')));
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_action_text_rich_texts_on_body_tsvector
      ON action_text_rich_texts USING gin(to_tsvector('simple', coalesce(body, '')));
    SQL

    add_index :posts, :title, using: :gin, opclass: :gin_trgm_ops,
              name: "index_posts_on_title_gin", algorithm: :concurrently, if_not_exists: true
    add_index :action_text_rich_texts, :body, using: :gin, opclass: :gin_trgm_ops,
              name: "index_action_text_rich_texts_on_body_gin", algorithm: :concurrently, if_not_exists: true
  end
end
