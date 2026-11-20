class CheckPostCommentJob < ApplicationJob
  queue_as :default

  def perform(comment_id, ip = nil)
    comment = Post::Comment.find_by(id: comment_id)
    return unless comment

    if comment.spam?(ip: ip)
      Rails.logger.info("[CheckPostCommentJob] Spam detected, destroying comment #{comment.id}")
      comment.destroy!
    end
  end
end
