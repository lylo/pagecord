class AvatarModerationJob < ApplicationJob
  queue_as :low

  retry_on StandardError, wait: :polynomially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotUnique

  def perform(blog_id)
    blog = Blog.kept.find_by(id: blog_id)
    return unless blog&.needs_avatar_moderation?

    with_sentry_context(user: blog.user, blog: blog) do
      Rails.logger.info "[AvatarModeration] Moderating avatar for #{blog.subdomain}"

      moderator = ContentModerator.new(blog)
      moderator.moderate

      save_moderation_result!(blog, moderator.result)

      log_result(moderator, blog)
    end
  end

  private

    def save_moderation_result!(blog, result)
      moderation = blog.avatar_moderation || blog.build_avatar_moderation

      moderation.update!(
        status: result.status,
        flags: result.flags,
        category_scores: result.scores,
        moderated_at: Time.current,
        fingerprint: blog.avatar_moderation_fingerprint,
        model_version: result.model_version,
        reviewed_at: nil
      )
    end

    def log_result(moderator, blog)
      if moderator.error?
        Rails.logger.warn "[AvatarModeration] Error #{blog.subdomain}: #{moderator.result.flags[:error]}"
      elsif moderator.flagged?
        Rails.logger.info "[AvatarModeration] FLAGGED #{blog.subdomain}: #{blog.avatar_moderation.flagged_categories.join(', ')}"
      else
        Rails.logger.info "[AvatarModeration] Clean #{blog.subdomain}"
      end
    end
end
