# Slug => template. Shared by config/routes.rb and Public::PagesController, and
# defined here so drawing the routes doesn't autoload ActionController.
MARKETING_PAGES = %w[
  terms privacy ai faq brand
  personal-website minimalist-blogging blogging-by-email indie-blogging-platform
].index_with { |slug| slug.tr("-", "_") }.freeze
