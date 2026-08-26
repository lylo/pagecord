require "test_helper"

class Public::PricesControllerTest < ActionDispatch::IntegrationTest
  test "returns the discounted price for discounted countries" do
    Pricing::DISCOUNTED_COUNTRIES.each do |country_code|
      get prices_path, headers: { "CF-IPCountry" => country_code }

      assert_response :success
      assert_equal "25", response.parsed_body["annual"]
      assert_equal "50", response.parsed_body["supporter"]
    end
  end

  test "returns the standard price for other countries" do
    get prices_path, headers: { "CF-IPCountry" => "US" }

    assert_response :success
    assert_equal Subscription.price, response.parsed_body["annual"]
    assert_equal Subscription.price(:monthly), response.parsed_body["monthly"]
  end

  # A shared cache would serve one country's prices to every country.
  test "is cached privately, never publicly" do
    get prices_path

    assert_includes @response.headers["Cache-Control"], "private"
    assert_includes @response.headers["Cache-Control"], "max-age=3600"
    assert_not_includes @response.headers["Cache-Control"], "public"
  end
end
