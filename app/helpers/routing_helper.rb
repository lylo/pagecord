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

  def blog_home_path(blog, options = {})
    route_for_blog(blog, "blog_posts", "path", options)
  end

  def blog_home_url(blog, options = {})
    route_for_blog(blog, "blog_posts", "url", options)
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

  def open_graph_image_url_for(post)
    route_for_blog(post.blog, "open_graph_image", "url", post_token: post.token)
  end

  def email_subscriber_confirmation_url_for(email_subscriber)
    email_subscriber_confirmation_url(email_subscriber.token, host: host(email_subscriber.blog))
  end

  def email_subscriber_unsubscribe_url_for(email_subscriber)
    email_subscriber_unsubscribe_url(email_subscriber.token, host: host(email_subscriber.blog))
  end

  def email_subscriber_one_click_unsubscribe_url_for(email_subscriber)
    email_subscriber_one_click_unsubscribe_url(email_subscriber.token, host: host(email_subscriber.blog))
  end

  private

    def route_for_blog(blog, route_name, type, options = {})
      route_options = options.merge(host: host(blog))

      send("#{route_name}_#{type}", route_options)
    end

    def host(blog)
      blog.custom_domain.present? ? blog.custom_domain : "#{blog.subdomain}.#{Rails.application.config.x.domain}"
    end
end
