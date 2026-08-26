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

  # Every marketing page is page cached into public/, so a single rendering is
  # served to everyone. Prices here are the standard ones; the country specific
  # price belongs on the home page, which is not cached.
  test "marketing pages show the same prices in every country" do
    MARKETING_PAGES.each do |page|
      path = public_send("#{page}_path")

      get path, headers: { "CF-IPCountry" => "IN" }
      discounted = response.body.scan(/\$\d+/)

      get path, headers: { "CF-IPCountry" => "US" }

      assert_equal discounted, response.body.scan(/\$\d+/), "#{page} prices by country"
    end
  end

  test "pricing redirects to the home page pricing section" do
    get pricing_path

    assert_redirected_to "/#pricing"
  end
end
