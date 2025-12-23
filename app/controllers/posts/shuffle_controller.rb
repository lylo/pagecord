class Posts::ShuffleController < ApplicationController
  include RoutingHelper

  def show
    if post = random_post
      redirect_to post_url(post), allow_other_host: true
    else
      redirect_to root_path, alert: "No posts available right now"
    end
  end

  private

    def random_post
      Post.visible.posts
        .joins(blog: :user)
        .where(blogs: { allow_search_indexing: true })
        .where(users: { discarded_at: nil })
        .where("posts.published_at > ?", 1.month.ago)
        .order("RANDOM()")
        .first
    end
end
