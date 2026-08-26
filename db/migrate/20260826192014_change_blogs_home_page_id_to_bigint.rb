class ChangeBlogsHomePageIdToBigint < ActiveRecord::Migration[8.2]
  def up
    # posts.id is bigint; this was the one int4 foreign key in the schema.
    change_column :blogs, :home_page_id, :bigint
  end

  def down
    change_column :blogs, :home_page_id, :integer
  end
end
