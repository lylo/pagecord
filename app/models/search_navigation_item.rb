class SearchNavigationItem < NavigationItem
  validates :type, uniqueness: { scope: :blog_id }

  def label
    I18n.t("search.submit")
  end

  def link_url
    Rails.application.routes.url_helpers.blog_search_path
  end

  def label_hidden?
    true
  end

  def icon
    "icons/search.svg"
  end
end
