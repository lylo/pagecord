require "test_helper"

class CustomDomainHelperTest < ActionView::TestCase
  include CustomDomainHelper

  def setup
    @request = ActionDispatch::TestRequest.create
  end

  test "custom_domain_request? returns true for custom domain in production" do
    Rails.env = "production"
    @request.host = "custom.com"
    assert custom_domain_request?
  end

  test "custom_domain_request? returns false for default domain in production" do
    Rails.env = "production"
    @request.host = "pagecord.com"
    refute custom_domain_request?
  end
end