class PageNavigationItem < NavigationItem
  belongs_to :post

  validates :post, presence: true

  def label
    post&.display_title
  end

  def link_url
    Rails.application.routes.url_helpers.blog_post_path(post.slug)
  end
end
