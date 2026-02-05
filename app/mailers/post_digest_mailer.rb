class PostDigestMailer < PostmarkMailer
  include PostsHelper
  include RoutingHelper

  layout "mailer_digest"

  helper :routing
  helper_method :without_action_text_image_wrapper, :strip_video_tags

  def weekly_digest
    @digest = params[:digest]
    @posts = @digest.posts.with_rich_text_content.order(published_at: :desc)
    @subscriber = params[:subscriber]

    set_broadcast_headers(@digest, @subscriber)

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

  def individual
    @digest = params[:digest]
    @post = @digest.posts.with_rich_text_content.first
    @subscriber = params[:subscriber]

    set_broadcast_headers(@digest, @subscriber)

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

    def set_broadcast_headers(digest, subscriber)
      one_click_url = email_subscriber_one_click_unsubscribe_url_for(subscriber)
      headers["List-Unsubscribe"] = "<#{one_click_url}>"
      headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
      headers["X-PM-Message-Stream"] = "broadcast"
      headers["X-PM-Metadata-SubscriberToken"] = subscriber.token
    end

    def sender_address_for(blog)
      "#{blog.display_name} <digest@newsletters.pagecord.com>"
    end
end
