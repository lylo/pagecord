require "test_helper"

class Public::PagesControllerTest < ActionDispatch::IntegrationTest
  MARKETING_PAGES = %w[
    terms privacy faq brand
    pagecord_vs_about_me pagecord_vs_medium pagecord_vs_hey_world
    pagecord_vs_wordpress pagecord_vs_substack
    personal_website minimalist_blogging blogging_by_email
    blogger_alternative indie_blogging_platform
  ].freeze

  test "renders every marketing page" do
    MARKETING_PAGES.each do |page|
      get public_send("#{page}_path")

      assert_response :success, "#{page} did not render"
    end
  end

  test "non-html formats are not acceptable" do
    get faq_path(format: :json)

    assert_response :not_acceptable
  end

  test "pricing redirects to the home page pricing section" do
    get pricing_path

    assert_redirected_to "/#pricing"
  end
end
