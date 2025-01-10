namespace :post_digests do
  desc "Deliver post digests to relevant subscribers"
  task deliver: :environment do
    blogs = Blog.where(email_subscriptions_enabled: true)
    blogs.find_each do |blog|
      if blog.user.kept? && blog.user.subscribed?
        GeneratePostDigestJob.perform_later(blog.id)
      end
    end
  end
end
