# Preview all emails at http://localhost:3000/rails/mailers/post_digest_mailer
class PostDigestMailerPreview < ActionMailer::Preview
  def weekly_digest
    PostDigest.destroy_all
    blog = Blog.find_by(subdomain: "joel")
    digest = PostDigest.generate_for(blog)
    PostDigestMailer.with(digest: digest, subscriber: digest.blog.email_subscribers.first).weekly_digest
  end
end
