class PostDigestMailer < PostmarkMailer
  include PostsHelper
  include RoutingHelper

  BROADCAST_FROM_DOMAIN = "newsletters.pagecord.com"

  layout "mailer_digest"

  helper :routing
  helper_method :without_action_text_image_wrapper, :strip_video_tags

  def weekly_digest
    digest = params[:digest]
    @digest = digest

    @posts = digest.posts.with_rich_text_content.order(published_at: :desc)
    @subscriber = params[:subscriber]

    one_click_url = email_subscriber_one_click_unsubscribe_url_for(@subscriber)
    headers["List-Unsubscribe"] = "<#{one_click_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
    headers["X-PM-Message-Stream"] = "broadcast"

    I18n.with_locale(@subscriber.blog.locale) do
      mail(
        to: @subscriber.email,
        from: sender_address_for(@subscriber.blog),
        reply_to: "digest-reply-#{@digest.masked_id}@post.pagecord.com",
        subject: @digest.subject,
        message_stream: "broadcast"
      )
    end
  end

  private

    def sender_address_for(blog)
      "#{blog.display_name} <digest@#{BROADCAST_FROM_DOMAIN}>"
    end
end
