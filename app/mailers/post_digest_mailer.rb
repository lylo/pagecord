class PostDigestMailer < PostmarkMailer
  include PostsHelper
  include RoutingHelper

  layout "mailer_digest"

  helper :routing
  helper_method :without_action_text_image_wrapper

  def weekly_digest
    digest = params[:digest]

    @posts = digest.posts.order(published_at: :desc)
    @subscriber = params[:subscriber]

    one_click_url = email_subscriber_one_click_unsubscribe_url_for(@subscriber)
    headers["List-Unsubscribe"] = "<#{one_click_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
    
    mail(
      to: @subscriber.email,
      from: sender_address_for(@subscriber.blog),
      subject: "New posts from #{@subscriber.blog.display_name} - #{Date.current.to_formatted_s(:long)}"
    )
  end

  private

    def sender_address_for(blog)
      "#{blog.display_name} <no-reply@notifications.pagecord.com>"
    end
end
