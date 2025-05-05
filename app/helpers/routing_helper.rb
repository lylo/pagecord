module RoutingHelper
  def post_link(post, type)
    if post.blog.custom_domain?
      if post.url_title.present?
        send("custom_post_with_title_#{type}", post.url_title, post.token, host: post.blog.custom_domain)
      else
        send("custom_post_without_title_#{type}", post.token, host: post.blog.custom_domain)
      end
    else
      if post.url_title.present?
        send("post_with_title_#{type}", post.blog.name, post.url_title, post.token)
      else
        send("post_without_title_#{type}", post.blog.name, post.token)
      end
    end
  end

  def post_path(post)
    post_link(post, "path")
  end

  def post_url(post)
    post_link(post, "url")
  end

  def blog_home(blog, type)
    if blog.custom_domain.present?
      send("custom_blog_posts_#{type}", host: blog.custom_domain)
    else
      send("blog_posts_#{type}", name: blog.name)
    end
  end

  def blog_home_path(blog)
    blog_home(blog, "path")
  end

  def blog_home_url(blog)
    blog_home(blog, "url")
  end

  def rss_feed_path(blog)
    if blog.custom_domain.present?
      custom_blog_feed_xml_path(host: blog.custom_domain)
    else
      blog_feed_xml_path(name: blog.name)
    end
  end

  def email_subscribers_path_for_domain
    if custom_domain_request?
      custom_email_subscribers_path
    else
      email_subscribers_path
    end
  end

  def email_subscriber_unsubscribe_path_for(subscriber)
    if custom_domain_request?
      custom_email_subscriber_unsubscribe_path(subscriber.token)
    else
      email_subscriber_unsubscribe_path(subscriber.token)
    end
  end

  # REPLIES

  def new_post_reply_path_for(post)
    if post.blog.custom_domain?
      new_custom_post_reply_path(post.token)
    else
      new_post_reply_path(post.blog.name, post.token)
    end
  end

  def post_replies_path_for(post)
    if post.blog.custom_domain?
      custom_post_replies_path(post.token)
    else
      post_replies_path(post.blog.name, post.token)
    end
  end

  # UPVOTES

  def post_upvote_path_for(post, upvote)
    if post.blog.custom_domain?
      custom_post_upvote_path(post.token, upvote)
    else
      post_upvote_path(post.blog.name, post.token, upvote)
    end
  end

  def post_upvotes_path_for(post)
    if post.blog.custom_domain?
      custom_post_upvotes_path(post.token)
    else
      post_upvotes_path(post.blog.name, post.token)
    end
  end
end
