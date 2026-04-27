require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  test "should get home page" do
    get root_path
    assert_response :success
  end

  test "should render home page when logged in" do
    user = users(:joel)
    login_as user

    get root_path
    assert_response :success
    assert_select "a", text: "Dashboard"
  end

  test "should render localized price for Brazil" do
    # Inject the CF-IPCountry header with BR value
    get root_path, headers: { "CF-IPCountry" => "BR" }

    assert_response :success
    assert_select "body", text: /\$25/
  end

  test "should render localized price for India" do
    # Inject the CF-IPCountry header with IN value
    get root_path, headers: { "CF-IPCountry" => "IN" }

    assert_response :success
    assert_select "body", text: /\$25/
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
