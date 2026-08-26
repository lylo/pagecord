require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  test "should get home page" do
    get root_path
    assert_response :success
    assert_select "h1", text: "A blog you'll actually keep updated"
  end

  test "should publicly cache unattributed home page" do
    get root_path

    assert_response :success
    assert_includes @response.headers["Cache-Control"], "s-maxage=3600"
  end

  test "should not publicly cache attributed home page" do
    get root_path, params: { utm_source: "reddit", utm_campaign: "obsidian_blog" }

    assert_response :success
    assert_not_includes @response.headers["Cache-Control"] || "", "s-maxage"
  end

  # The header is the same whoever is looking, so the page stays cacheable.
  test "should render the same header when logged in" do
    get root_path
    signed_out = css_select("nav a").map(&:text)

    login_as users(:joel)
    get root_path

    assert_response :success
    assert_equal signed_out, css_select("nav a").map(&:text)
  end

  # The page is publicly cached, so it renders the standard price for everyone
  # and the price controller swaps in the visitor's own.
  test "should render the standard price whatever the country" do
    Pricing::DISCOUNTED_COUNTRIES.each do |country_code|
      get root_path, headers: { "CF-IPCountry" => country_code }

      assert_response :success
      assert_select "[data-price-target=amount]", text: Subscription.price
    end
  end

  test "should render default price when no country header" do
    # No CF-IPCountry header
    get root_path

    assert_response :success
    assert_select "body", text: /\$39/
  end
end
