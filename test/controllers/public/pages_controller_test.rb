require "test_helper"

class Public::PagesControllerTest < ActionDispatch::IntegrationTest
  test "renders every marketing page" do
    Public::PagesController::PAGES.each do |slug|
      get public_page_path(slug)

      assert_response :success, "#{slug} did not render"
    end
  end

  test "non-html formats are not acceptable" do
    get public_page_path("faq", format: :json)

    assert_response :not_acceptable
  end

  test "pricing redirects to the home page pricing section" do
    get pricing_path

    assert_redirected_to "/#pricing"
  end
end
