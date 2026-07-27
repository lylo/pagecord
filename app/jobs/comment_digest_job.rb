class CommentDigestJob < ApplicationJob
  queue_as :default

  WINDOW = 4.hours

  # Batched by blog rather than by comment: one email per blog is the unit of
  # work, and batching comments would split a blog across two digests.
  def perform
    blogs_with_comments_waiting.find_each do |blog|
      next unless blog.accepts_comments?
      next unless claim_digest_window_for(blog)

      comments = waiting_for(blog)
      next if comments.empty?

      Rails.logger.info "[CommentDigest] Sending #{comments.size} comments to blog #{blog.id}"
      CommentMailer.with(blog: blog, comments: comments).digest.deliver_later
    end
  end

  private

    def blogs_with_comments_waiting
      Blog.kept.includes(:user).where(id: waiting.joins(:post).select("posts.blog_id"))
    end

    def waiting_for(blog)
      blog.comments.merge(waiting).chronologically.includes(:post).to_a
    end

    def waiting
      Post::Comment.pending.where(created_at: WINDOW.ago..)
    end

    def claim_digest_window_for(blog)
      Rails.cache.write(cache_key_for(blog), true, expires_in: WINDOW + 30.minutes, unless_exist: true)
    end

    def cache_key_for(blog)
      window = Time.current.to_i / WINDOW.to_i
      "comment_digest:#{blog.id}:#{window}"
    end
end
