require "test_helper"

class Blogs::FormNoncesControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "#{blogs(:joel).subdomain}.#{Rails.application.config.x.domain}"
  end

  test "sets a nonce cookie matching the session" do
    post blog_form_nonce_path

    assert_response :no_content
    assert cookies["form_nonce"].present?
    assert_equal session[:form_nonce], cookies["form_nonce"]
  end
end
