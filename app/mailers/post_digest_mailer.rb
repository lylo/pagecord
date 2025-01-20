class PostDigestMailer < ApplicationMailer
  include PostsHelper

  layout "mailer_digest"

  helper_method :blog_url_for, :post_url_for, :unsubscribe_path_for, :without_action_text_image_wrapper

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
      "#{blog.display_name} <#{blog.name}@notifications.pagecord.com>"
    end

    def blog_url_for(blog)
      if blog.custom_domain?
        custom_blog_posts_url(blog)
      else
        blog_posts_url(name: blog.name)
      end
    end

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
