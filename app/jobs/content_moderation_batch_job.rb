class ContentModerationBatchJob < ApplicationJob
  queue_as :default

  DELAY_BETWEEN_POSTS = 1.second
  MAX_POSTS_PER_RUN = 100
  LOOKBACK_PERIOD = 2.hours

  def perform
    posts = Post.kept
                .published
                .where(hidden: false)
                .where("posts.updated_at >= ?", LOOKBACK_PERIOD.ago)
                .moderation_pending
                .includes(:blog)
                .limit(MAX_POSTS_PER_RUN)

    Rails.logger.info "[ContentModerationBatch] Queuing #{posts.count} posts for moderation"

    posts.each_with_index do |post, index|
      ContentModerationJob.set(wait: index * DELAY_BETWEEN_POSTS).perform_later(post.id)
    end
  end
end
