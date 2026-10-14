require "test_helper"

class Public::PagesControllerTest < ActionDispatch::IntegrationTest
  test "renders every marketing page" do
    MARKETING_PAGES.each_value do |page|
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

  test "the features page has the walkthrough and compares the plans" do
    get features_path

    assert_select "#walkthrough video"
    assert_select "#compare table tbody", 2
  end

  test "a page with two signup letters gives each its own field" do
    get minimalist_blogging_path

    assert_select "input#title", 1
    assert_select "input#closing_title", 1
    assert_select "label[for=closing_title]", 1
  end

  test "pricing redirects to the home page pricing section" do
    get pricing_path

    assert_redirected_to "/#pricing"
  end
end
