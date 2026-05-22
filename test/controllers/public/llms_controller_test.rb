require "test_helper"

class Public::LlmsControllerTest < ActionDispatch::IntegrationTest
  test "should get llms.txt" do
    get llms_txt_path
    assert_response :success
    assert_equal "text/plain; charset=utf-8", @response.content_type
    assert_includes @response.body, "# Pagecord"
    assert_includes @response.body, "Blog Without The Slog"
  end
end
