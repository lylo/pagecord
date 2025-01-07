# Preview all emails at http://localhost:3000/rails/mailers/post_digest_mailer
class PostDigestMailerPreview < ActionMailer::Preview
  def weekly_digest
    PostDigestMailer.with(digest: PostDigest.last, subscriber: PostDigest.last.blog.email_subscribers.first).weekly_digest
  end
end
