class CustomNavigationItem < NavigationItem
  validates :url, presence: true

  def link_url
    url
  end
end
