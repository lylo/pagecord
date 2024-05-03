module RoutingHelper

  def post_link(post, type)
    if custom_domain_request?
      if post.url_title.present?
        send("custom_post_with_title_#{type}", post.url_title, post.url_id, host: post.user.custom_domain)
      else
        send("custom_post_without_title_#{type}", post.url_id, host: post.user.custom_domain)
      end
    else
      if post.url_title.present?
        send("post_with_title_#{type}", post.user.username, post.url_title, post.url_id)
      else
        send("post_without_title_#{type}", post.user.username, post.url_id)
      end
    end
  end

  def post_path(post)
    post_link(post, 'path')
  end

  def post_url(post)
    post_link(post, 'url')
  end

  def user_home(user, type)
    if custom_domain_request?
      send("custom_user_posts_#{type}", host: user.custom_domain)
    else
      send("user_posts_#{type}", username: user.username)
    end
  end

  def user_home_path(user)
    user_home(user, 'path')
  end

  def user_home_url(user)
    user_home(user, 'url')
  end

  def custom_domain_request?
    !%w[pagecord.com localhost].include?(request.host)
  end
end