class PostDigestMailer < ApplicationMailer
  layout "mailer_digest"

  helper_method :post_url_for, :unsubscribe_path_for

  def weekly_digest
    @digest = params[:digest]
    @subscriber = params[:subscriber]

    mail(to: @subscriber.email, subject: "New posts from #{@subscriber.blog.display_name}")
  end

  private

    def post_url_for(post)
      if post.blog.custom_domain?
        custom_post_with_title_url(title: post.url_title, token: post.token)
      else
        post_with_title_url(name: post.blog.name, title: post.url_title, token: post.token)
      end
    end

    def unsubscribe_path_for(subscriber)
      if subscriber.blog.custom_domain?
        custom_email_subscriber_unsubscribe_url(subscriber.token)
      else
        email_subscriber_unsubscribe_url(name: subscriber.blog.name, token: subscriber.token)
      end
    end
end
