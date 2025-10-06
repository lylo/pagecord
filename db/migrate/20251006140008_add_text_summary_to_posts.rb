class AddTextSummaryToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :text_summary, :text

    # Backfill existing posts
    reversible do |dir|
      dir.up do
        Post.find_each do |post|
          post.update_column(:text_summary, post.send(:text_content))
        end
      end
    end
  end
end
