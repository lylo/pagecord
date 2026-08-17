# Preview all emails at http://localhost:3000/rails/mailers/post_digest_mailer
class PostDigestMailerPreview < ActionMailer::Preview
  def weekly_digest
    blog = preview_blog
    digest = blog.post_digests.weekly_digest.last || create_weekly_digest(blog)
    PostDigestMailer.with(digest: digest, subscriber: blog.email_subscribers.first).weekly_digest
  end

  def individual
    blog = preview_blog
    digest = digest_for_param(blog) || blog.post_digests.individual.last || create_individual_digest(blog)
    PostDigestMailer.with(digest: digest, subscriber: blog.email_subscribers.first).individual
  end

  private

    # ?post=<token> previews a specific post rather than the latest, reusing
    # its digest if one already exists.
    def digest_for_param(blog)
      return unless params[:post]

      post = blog.all_posts.find_by!(token: params[:post])
      blog.post_digests.individual.joins(:digest_posts).find_by(digest_posts: { post_id: post.id }) ||
        PostDigest.create!(blog: blog, kind: :individual).tap { |digest| digest.digest_posts.create!(post: post) }
    end

    def preview_blog
      Blog.find_by(subdomain: "joel").tap do |blog|
        blog.locale = params[:locale] if params[:locale]
      end
    end

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
