require "test_helper"

class MarketingFlagTest < ActionDispatch::IntegrationTest
  test "custom code appears on marketing pages only when globally enabled" do
    get root_url
    assert_no_match(/Custom code/, response.body)

    ENV["FEATURE_CUSTOM_CODE"] = "true"
    begin
      get root_url
      assert_match(/Custom code/, response.body)

      get "/pagecord-vs-medium"
      assert_match(/Custom code/, response.body)

      get "/llms.txt"
      assert_match(/Custom code/, response.body)
    ensure
      ENV.delete("FEATURE_CUSTOM_CODE")
    end
  end
end
