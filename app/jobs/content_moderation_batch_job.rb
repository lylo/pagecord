class ContentModerationBatchJob < ApplicationJob
  queue_as :default

  DELAY_BETWEEN_POSTS = 1.second
  MAX_POSTS_PER_RUN = 100

  # Daily fallback job to catch any posts that slipped through event-driven moderation
  def perform
    posts = Post.moderatable
                .moderation_pending
                .includes(:blog)
                .limit(MAX_POSTS_PER_RUN)

    Rails.logger.info "[ContentModerationBatch] Queuing #{posts.count} posts for moderation"

    posts.each_with_index do |post, index|
      ContentModerationJob.set(wait: index * DELAY_BETWEEN_POSTS).perform_later(post.id)
    end
  end
end
