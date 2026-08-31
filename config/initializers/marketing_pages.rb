# Slug => template. Shared by config/routes.rb and Public::PagesController, and
# defined here so drawing the routes doesn't autoload ActionController.
MARKETING_PAGES = %w[
  terms privacy ai faq brand
  pagecord-vs-about-me pagecord-vs-medium pagecord-vs-hey-world
  pagecord-vs-wordpress pagecord-vs-substack
  personal-website minimalist-blogging blogging-by-email
  blogger-alternative indie-blogging-platform
].index_with { |slug| slug.tr("-", "_") }.freeze
