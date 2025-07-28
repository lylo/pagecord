namespace :posts do
  desc "Clear raw_content field for posts older than 3 weeks"
  task clear_old_raw_content: :environment do
    cutoff_date = 3.weeks.ago
    posts_updated = Post.where("created_at < ? AND raw_content IS NOT NULL", cutoff_date)
                        .update_all(raw_content: nil)

    puts "Cleared raw_content for #{posts_updated} posts created before #{cutoff_date.strftime('%B %d, %Y')}"
  end
end
