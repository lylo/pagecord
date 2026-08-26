class AddMissingNotNulls < ActiveRecord::Migration[8.2]
  def change
    # Each of these already has a default or a presence validation; the columns
    # just never said so.
    change_column_null :blogs, :layout, false, 0
    change_column_null :users, :verified, false, false
    change_column_null :users, :onboarding_state, false, "account_created"
    change_column_null :content_moderations, :category_scores, false, {}
    change_column_null :content_moderations, :flags, false, {}

    # Queried as where(is_unique: true), so a NULL row silently vanished from
    # analytics rather than counting as not unique.
    change_column_null :page_views, :is_unique, false, false
  end
end
