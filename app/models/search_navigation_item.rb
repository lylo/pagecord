class SearchNavigationItem < NavigationItem
  validates :type, uniqueness: { scope: :blog_id }

  before_validation :set_label, on: :create

  def label
    I18n.t("search.submit")
  end

  def link_url
    Rails.application.routes.url_helpers.blog_search_path
  end

  def icon
    "icons/search.svg"
  end

  private

    def set_label
      self.label = "Search"
    end
end
