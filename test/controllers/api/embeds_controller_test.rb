require "test_helper"
require "mocha/minitest"

class Api::EmbedsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
    host_subdomain! @blog.subdomain
  end

  test "should return embed URL when og:video found" do
    # Mock the URL response with og:video meta tag
    mock_html = <<~HTML
      <html>
        <head>
          <meta property="og:video" content="https://bandcamp.com/EmbeddedPlayer/v=2/album=123/"/>
        </head>
      </html>
    HTML

    URI.stubs(:open).with("https://example.com/album").returns(StringIO.new(mock_html))

    post "/api/embeds/bandcamp", params: { url: "https://example.com/album" }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "https://bandcamp.com/EmbeddedPlayer/v=2/album=123/", json_response["embed_url"]
  end

  test "should return error when no og:video found" do
    # Mock the URL response without og:video meta tag
    mock_html = <<~HTML
      <html>
        <head>
          <title>Some Page</title>
        </head>
      </html>
    HTML

    URI.stubs(:open).with("https://example.com/album").returns(StringIO.new(mock_html))

    post "/api/embeds/bandcamp", params: { url: "https://example.com/album" }

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal "No og:video found", json_response["error"]
  end

  test "should handle network errors gracefully" do
    URI.stubs(:open).with("https://example.com/album").raises(StandardError.new("Network error"))

    post "/api/embeds/bandcamp", params: { url: "https://example.com/album" }

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal "Network error", json_response["error"]
  end

  test "should work on custom domains" do
    # Test that the endpoint works on custom domains too
    @blog.update!(custom_domain: "myblog.com")
    host! "myblog.com"

    mock_html = <<~HTML
      <html>
        <head>
          <meta property="og:video" content="https://bandcamp.com/EmbeddedPlayer/v=2/album=456/"/>
        </head>
      </html>
    HTML

    URI.stubs(:open).with("https://example.com/album").returns(StringIO.new(mock_html))

    post "/api/embeds/bandcamp", params: { url: "https://example.com/album" }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "https://bandcamp.com/EmbeddedPlayer/v=2/album=456/", json_response["embed_url"]
  end

  test "should skip CSRF token verification" do
    # This test ensures the endpoint works without CSRF tokens (important for API endpoints)
    post "/api/embeds/bandcamp", params: { url: "https://example.com/album" }

    # Should not get InvalidAuthenticityToken error
    assert_not_equal "ActionController::InvalidAuthenticityToken", response.body
  end

  private

  def host_subdomain!(name)
    host! "#{name}.#{Rails.application.config.x.domain}"
  end
end