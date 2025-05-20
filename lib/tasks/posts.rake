namespace :posts do
  desc "Backfill slugs for posts"
  task backfill_slugs: :environment do
    Post.find_each do |post|
      post.slug = post.to_title_param
      post.save!
    end
  end
end
