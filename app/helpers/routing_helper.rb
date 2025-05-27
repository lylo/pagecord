module RoutingHelper
  def post_link(post, type)
    send("blog_post_#{type}", post.slug, host: host(post.blog))
  end

  def post_path(post)
    post_link(post, "path")
  end

  def post_url(post)
    post_link(post, "url")
  end

  def blog_home_path(blog)
    route_for_blog(blog, "blog_posts", "path")
  end

  def blog_home_url(blog)
    route_for_blog(blog, "blog_posts", "url")
  end

  def rss_feed_path(blog)
    route_for_blog(blog, "blog_feed_xml", "path")
  end

  def rss_feed_url(blog)
    route_for_blog(blog, "blog_feed_xml", "url")
  end

  def sitemap_url_for(blog)
    route_for_blog(blog, "blog_sitemap", "url")
  end

  def email_subscriber_confirmation_url_for(email_subscriber)
    route_for_blog(email_subscriber.blog, "email_subscriber_confirmation", "url", email_subscriber.token)
  end

  def email_subscriber_unsubscribe_url_for(email_subscriber)
    route_for_blog(email_subscriber.blog, "email_subscriber_unsubscribe", "url", email_subscriber.token)
  end

  private

    def route_for_blog(blog, route_name, type, *args)
      options = { host: host(blog) }

      send("#{route_name}_#{type}", *args, options)
    end

    def host(blog)
      blog.custom_domain.present? ? blog.custom_domain : "#{blog.name}.#{Rails.application.config.x.domain}"
    end
end
