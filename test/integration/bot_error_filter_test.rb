require "test_helper"

class BotErrorFilterTest < ActionDispatch::IntegrationTest
  test "rejects multipart request with empty content length" do
    post "/",
      headers: {
        "CONTENT_TYPE" => "multipart/form-data; boundary=----WebKitFormBoundary",
        "CONTENT_LENGTH" => "0"
      }

    assert_response :bad_request
    assert_equal "Bad Request\n", response.body
  end

  test "rejects multipart request with missing boundary" do
    post "/",
      headers: {
        "CONTENT_TYPE" => "multipart/form-data",
        "CONTENT_LENGTH" => "100"
      },
      params: "some body content"

    assert_response :bad_request
    assert_equal "Bad Request\n", response.body
  end

  test "allows valid multipart requests with boundary and content" do
    # Create a simple valid multipart body
    boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
    body = "--#{boundary}\r\n" \
           "Content-Disposition: form-data; name=\"test\"\r\n\r\n" \
           "value\r\n" \
           "--#{boundary}--\r\n"

    post "/",
      headers: {
        "CONTENT_TYPE" => "multipart/form-data; boundary=#{boundary}"
      },
      params: body

    # Should not be rejected by the filter
    assert_not_equal "Bad Request\n", response.body
  end
end
