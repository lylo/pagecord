class CommentDigestJob < ApplicationJob
  queue_as :default

  # Must match the cron interval in config/schedule.rb. A quiet day sends
  # nothing at all, so this is only ever a nudge about something new.
  WINDOW = 1.day

  def perform
    blogs_with_new_comments.find_each do |blog|
      next unless blog.accepts_comments?
      next unless claim_digest_window_for(blog)

      comments = waiting_for(blog)
      next if comments.empty?

      Rails.logger.info "[CommentDigest] Sending #{comments.size} comments to blog #{blog.id}"
      CommentMailer.with(blog: blog, comments: comments).digest.deliver_later
    end
  end

  private

    def blogs_with_new_comments
      Blog.kept.includes(:user).where(id: arrived_today.joins(:post).select("posts.blog_id"))
    end

    def waiting_for(blog)
      blog.comments.pending.chronologically.includes(:post).to_a
    end

    def arrived_today
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
