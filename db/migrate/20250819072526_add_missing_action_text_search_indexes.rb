class AddMissingActionTextSearchIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :action_text_rich_texts,
              [ :record_type, :name, :record_id ],
              where: "record_type = 'Post' AND name = 'content'",
              name: "index_action_text_rich_texts_on_post_content",
              algorithm: :concurrently
  end

  def down
    remove_index :action_text_rich_texts,
                  name: "index_action_text_rich_texts_on_post_content",
                  if_exists: true
  end
end
