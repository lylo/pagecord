class CheckPostCommentJob < ApplicationJob
  queue_as :default

  def perform(comment_id)
    comment = Post::Comment.find_by(id: comment_id)
    return unless comment

    # Clean comments stay pending until the blogger approves them. Spam never
    # reaches the moderation queue at all.
    if comment.spam?
      Rails.logger.info("[CheckPostCommentJob] Spam detected, destroying comment #{comment.id}")
      comment.destroy!
    end
  end
end
