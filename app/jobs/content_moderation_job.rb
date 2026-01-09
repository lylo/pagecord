class ContentModerationJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post
    return unless post.published? && !post.hidden? && !post.discarded?
    return unless post.needs_moderation?

    Rails.logger.info "[ContentModeration] Moderating post #{post.id} (#{post.blog.subdomain})"

    moderator = ContentModerator.new(post)
    moderator.moderate

    save_moderation_result!(post, moderator.result)

    if moderator.flagged?
      Rails.logger.info "[ContentModeration] FLAGGED post #{post.id}: #{post.content_moderation.flagged_categories.join(', ')}"
      AdminMailer.content_flagged_notification(post.id).deliver_later
    else
      Rails.logger.info "[ContentModeration] Clean post #{post.id}"
    end
  end

  private

    def save_moderation_result!(post, result)
      moderation = post.content_moderation || post.build_content_moderation

      moderation.update!(
        status: result.status,
        flags: result.flags,
        moderated_at: Time.current,
        fingerprint: post.moderation_fingerprint,
        model_version: result.model_version
      )
    end
end
