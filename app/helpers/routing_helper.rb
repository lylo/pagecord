module RoutingHelper
  def post_link(post, type)
    blog = post.blog

    case post.page? ? "flat" : blog.post_url_format
    when "prefix"
      send("blog_prefixed_post_#{type}", blog.post_url_prefix, post.slug, host: host(blog))
    when "dated"
      date = post.published_at
      return send("blog_post_#{type}", post.slug, host: host(blog)) if date.nil?

      send("blog_dated_post_#{type}", date.strftime("%Y"), date.strftime("%m"), date.strftime("%d"), post.slug, host: host(blog))
    else
      send("blog_post_#{type}", post.slug, host: host(blog))
    end
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

  def rss_feed_url(blog, options = {})
    route_for_blog(blog, "blog_feed_xml", "url", options)
  end

  def sitemap_url_for(blog)
    route_for_blog(blog, "blog_sitemap", "url")
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

  def micropub_endpoint_url
    micropub_url(host: "api.#{Rails.application.config.x.domain}")
  end

  private

    def route_for_blog(blog, route_name, type, options = {})
      route_options = options.symbolize_keys.merge(host: host(blog))

      public_send("#{route_name}_#{type}", **route_options)
    end

    def host(blog)
      blog.host
    end
end
