class PostsNavigationItem < NavigationItem
  validates :type, uniqueness: { scope: :blog_id }

  def link_url
    blog.posts_list_path
  end
end
