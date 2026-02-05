# Preview all emails at http://localhost:3000/rails/mailers/post_digest_mailer
class PostDigestMailerPreview < ActionMailer::Preview
  def weekly_digest
    blog = Blog.find_by(subdomain: "joel")
    digest = blog.post_digests.weekly_digest.last || create_weekly_digest(blog)
    PostDigestMailer.with(digest: digest, subscriber: blog.email_subscribers.first).weekly_digest
  end

  def individual
    blog = Blog.find_by(subdomain: "joel")
    digest = blog.post_digests.individual.last || create_individual_digest(blog)
    PostDigestMailer.with(digest: digest, subscriber: blog.email_subscribers.first).individual
  end

  private

    def create_weekly_digest(blog)
      posts = blog.posts.visible.order(published_at: :desc).limit(3)
      digest = PostDigest.create!(blog: blog, kind: :weekly_digest)
      posts.each { |post| digest.digest_posts.create!(post: post) }
      digest
    end

    def create_individual_digest(blog)
      post = blog.posts.visible.order(published_at: :desc).first
      digest = PostDigest.create!(blog: blog, kind: :individual)
      digest.digest_posts.create!(post: post)
      digest
    end
end
