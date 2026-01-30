class ContentModerationJob < ApplicationJob
  queue_as :low

  retry_on StandardError, wait: :polynomially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotUnique

  def perform(post_id)
    post = Post.moderatable.find_by(id: post_id)
    return unless post

    # Lock to prevent duplicate work when multiple jobs queued for same post
    post.with_lock do
      return unless post.needs_moderation?

      Rails.logger.info "[ContentModeration] Moderating #{post.blog.subdomain}/#{post.slug}"

      moderator = ContentModerator.new(post)
      moderator.moderate

      save_moderation_result!(post, moderator.result)

      log_result(moderator, post)
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

    def log_result(moderator, post)
      slug = "#{post.blog.subdomain}/#{post.slug}"

      if moderator.error?
        Rails.logger.warn "[ContentModeration] Error #{slug}: #{moderator.result.flags[:error]}"
      elsif moderator.flagged?
        Rails.logger.info "[ContentModeration] FLAGGED #{slug}: #{post.content_moderation.flagged_categories.join(', ')}"
      else
        Rails.logger.info "[ContentModeration] Clean #{slug}"
      end
    end
end
