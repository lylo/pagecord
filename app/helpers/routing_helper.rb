module RoutingHelper
  def post_link(post, type)
    if post.blog.custom_domain?
      send("blog_post_#{type}", post.slug, host: post.blog.custom_domain)
    else
      send("blog_post_#{type}", post.slug, host: "#{post.blog.name}.#{Rails.application.config.x.domain}")
    end
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

  private

    def route_for_blog(blog, route_name, type, *args)
      options = blog.custom_domain.present? ? { host: blog.custom_domain } : {}

      send("#{route_name}_#{type}", *args, options)
    end
end
