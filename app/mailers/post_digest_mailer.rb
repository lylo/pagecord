class PostDigestMailer < PostmarkMailer
  include PostsHelper

  layout "mailer_digest"

  helper :routing
  helper_method :blog_url_for, :unsubscribe_path_for, :without_action_text_image_wrapper

  def weekly_digest
    digest = params[:digest]

    @posts = digest.posts.order(published_at: :desc)
    @subscriber = params[:subscriber]

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

    def blog_url_for(blog)
      if blog.custom_domain?
        custom_blog_posts_url(blog)
      else
        blog_posts_url(name: blog.name)
      end
    end

    def unsubscribe_path_for(subscriber)
      if subscriber.blog.custom_domain?
        custom_email_subscriber_unsubscribe_url(subscriber.token, host: subscriber.blog.custom_domain)
      else
        email_subscriber_unsubscribe_url(name: subscriber.blog.name, token: subscriber.token)
      end
    end
end
