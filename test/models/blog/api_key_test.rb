require "test_helper"

class Blog::ApiKeyTest < ActiveSupport::TestCase
  test "an api key stops working when the account is discarded" do
    assert_equal blogs(:joel), Blog.find_by_api_key("test_api_key_for_fixtures")

    users(:joel).discard!

    assert_nil Blog.find_by_api_key("test_api_key_for_fixtures")
  end
end
