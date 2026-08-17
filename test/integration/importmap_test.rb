require "test_helper"

class ImportmapTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  APP_ONLY_MODULES = /codemirror|tagify|sortable|actiontext|activestorage/
  STIMULUS_IDENTIFIERS = /data-controller="([^"]+)"|controller: "([^"]+)"/

  BLOG_VIEWS = %w[blogs/**/*.erb shared/**/*.erb layouts/blog.html.erb]

  test "blog pages only expose blog modules" do
    host_subdomain! blogs(:joel).subdomain

    get blog_posts_path

    assert_response :success
    assert_includes imported_modules, "blog"
    assert_includes imported_modules, "controllers/media_embeds_controller"
    assert_no_match APP_ONLY_MODULES, imported_modules.join(" ")
  end

  test "every controller used by blog views is pinned in the blog map" do
    assert_empty controllers_used_in(BLOG_VIEWS) - Rails.application.config.importmap_blog.packages.keys
  end

  private
    def imported_modules
      JSON.parse(css_select("script[type=importmap]").first.text)["imports"].keys
    end

    def controllers_used_in(globs)
      globs.flat_map { |glob| Dir[Rails.root.join("app/views", glob)] }
        .flat_map { |view| File.read(view).scan(STIMULUS_IDENTIFIERS).flatten.compact }
        .flat_map(&:split)
        .uniq
        .map { |identifier| "controllers/#{identifier.gsub("--", "/").tr("-", "_")}_controller" }
    end
end
