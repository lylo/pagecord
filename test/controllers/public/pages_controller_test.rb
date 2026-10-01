require "test_helper"

class Public::PagesControllerTest < ActionDispatch::IntegrationTest
  MARKETING_PAGES = %w[
    terms privacy ai faq brand
    personal_website minimalist_blogging blogging_by_email indie_blogging_platform
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

  # Cached at the edge with the country in the cache key, so the price must
  # follow the visitor and the response must say what it varies on.
  test "marketing pages localise the price and declare what they vary on" do
    get minimalist_blogging_path, headers: { "CF-IPCountry" => "IN" }
    assert_select "body", text: /\$25/

    get minimalist_blogging_path, headers: { "CF-IPCountry" => "US" }
    assert_select "body", text: /\$39/

    assert_includes @response.headers["Vary"], "CF-IPCountry"
    assert_includes @response.headers["Cache-Control"], "s-maxage"
  end

  test "pricing redirects to the home page pricing section" do
    get pricing_path

    assert_redirected_to "/#pricing"
  end
end
