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

  test "should render home page when logged in" do
    user = users(:joel)
    login_as user

    get root_path
    assert_response :success
    assert_select "a", text: "Dashboard"
  end

  test "should render localized price for discounted countries" do
    PricingHelper::DISCOUNTED_COUNTRIES.each do |country_code|
      get root_path, headers: { "CF-IPCountry" => country_code }

      assert_response :success
      assert_select "body", text: /\$25/
    end
  end

  test "should render default price for other countries" do
    # Inject the CF-IPCountry header with US value
    get root_path, headers: { "CF-IPCountry" => "US" }

    assert_response :success
    assert_select "body", text: /\$39/
  end

  test "should render default price when no country header" do
    # No CF-IPCountry header
    get root_path

    assert_response :success
    assert_select "body", text: /\$39/
  end
end
