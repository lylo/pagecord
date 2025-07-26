class PostDigestMailer < PostmarkMailer
  include PostsHelper

  layout "mailer_digest"

  helper :routing
  helper_method :without_action_text_image_wrapper

  def weekly_digest
    digest = params[:digest]

    @posts = digest.posts.order(published_at: :desc)
    @subscriber = params[:subscriber]

    I18n.with_locale(@subscriber.blog.locale) do
      mail(
        to: @subscriber.email,
        from: sender_address_for(@subscriber.blog),
        subject: I18n.t("email_subscribers.mailers.weekly_digest.subject", blog_name: @subscriber.blog.display_name, date: Date.current.to_formatted_s(:long))
      )
    end
  end

  private

    def sender_address_for(blog)
      "#{blog.display_name} <no-reply@notifications.pagecord.com>"
    end
end
