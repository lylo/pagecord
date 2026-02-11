class TrackPageViewJob < ApplicationJob
  queue_as :default

  def perform(blog_id, post_token, ip, user_agent, path, referrer, country_code)
    blog = Blog.find_by(id: blog_id)
    return unless blog

    post = blog.all_posts.kept.published.released.find_by(token: post_token) if post_token.present?

    PageView.track(blog: blog, post: post, ip: ip, user_agent: user_agent, path: path, referrer: referrer, country_code: country_code)
  end
end
