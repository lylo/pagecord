class ContentModerationJob < ApplicationJob
  queue_as :low

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(post_id)
    post = Post.moderatable.find_by(id: post_id)
    return unless post&.needs_moderation?

    Rails.logger.info "[ContentModeration] Moderating #{post.blog.subdomain}/#{post.slug}"

    moderator = ContentModerator.new(post)
    moderator.moderate

    save_moderation_result!(post, moderator.result)

    if moderator.flagged?
      Rails.logger.info "[ContentModeration] FLAGGED #{post.blog.subdomain}/#{post.slug}: #{post.content_moderation.flagged_categories.join(', ')}"
    else
      Rails.logger.info "[ContentModeration] Clean #{post.blog.subdomain}/#{post.slug}"
    end
  end

  private

    def save_moderation_result!(post, result)
      moderation = post.content_moderation || post.build_content_moderation

      moderation.update!(
        status: result.status,
        flags: result.flags,
        category_scores: result.scores,
        moderated_at: Time.current,
        fingerprint: post.moderation_fingerprint,
        model_version: result.model_version
      )
    end
end
