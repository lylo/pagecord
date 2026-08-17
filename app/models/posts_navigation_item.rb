class PostsNavigationItem < NavigationItem
  validates :type, uniqueness: { scope: :blog_id }

  def link_url
    Rails.application.routes.url_helpers.blog_posts_list_path
  end
end
