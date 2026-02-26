class ContentModerationBatchJob < ApplicationJob
  queue_as :default

  LOOKBACK = 24.hours
  DELAY_BETWEEN_POSTS = 1.second
  MAX_POSTS_PER_RUN = 100

  def perform
    cutoff = LOOKBACK.ago
    posts = Post.moderatable
                .moderation_pending
                .where("posts.created_at > :cutoff OR posts.updated_at > :cutoff", cutoff: cutoff)
                .includes(:blog)
                .limit(MAX_POSTS_PER_RUN)

    Rails.logger.info "[ContentModerationBatch] Queuing #{posts.count} posts for moderation"

    posts.each_with_index do |post, index|
      ContentModerationJob.set(wait: index * DELAY_BETWEEN_POSTS).perform_later(post.id)
    end
  end
end
