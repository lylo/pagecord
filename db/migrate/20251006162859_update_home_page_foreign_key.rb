class UpdateHomePageForeignKey < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :blogs, :posts, column: :home_page_id
    add_foreign_key :blogs, :posts, column: :home_page_id, on_delete: :nullify
  end
end
