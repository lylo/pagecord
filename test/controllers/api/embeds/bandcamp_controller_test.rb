require "test_helper"
require "mocha/minitest"

class Api::Embeds::BandcampControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
    host_subdomain! @blog.subdomain
    Rails.cache.clear
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

    URI.stubs(:open).with(bandcamp_url, uri_open_options).returns(StringIO.new(mock_html))

    get "/api/embeds/bandcamp", params: { url: bandcamp_url }

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

    URI.stubs(:open).with(bandcamp_url, uri_open_options).returns(StringIO.new(mock_html))

    get "/api/embeds/bandcamp", params: { url: bandcamp_url }

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal "No og:video found", json_response["error"]
    assert_not_includes response.headers["Cache-Control"].to_s, "public"
  end

  test "should handle network errors gracefully" do
    URI.stubs(:open).with(bandcamp_url, uri_open_options).raises(StandardError.new("Network error"))

    get "/api/embeds/bandcamp", params: { url: bandcamp_url }

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

    URI.stubs(:open).with(bandcamp_url, uri_open_options).returns(StringIO.new(mock_html))

    get "/api/embeds/bandcamp", params: { url: bandcamp_url }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "https://bandcamp.com/EmbeddedPlayer/v=2/album=456/", json_response["embed_url"]
  end

  test "should work on the app domain, where drafts are previewed" do
    host! "example.com"

    mock_html = <<~HTML
      <html>
        <head>
          <meta property="og:video" content="https://bandcamp.com/EmbeddedPlayer/v=2/album=789/"/>
        </head>
      </html>
    HTML

    URI.stubs(:open).with(bandcamp_url, uri_open_options).returns(StringIO.new(mock_html))

    get "/api/embeds/bandcamp", params: { url: bandcamp_url }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "https://bandcamp.com/EmbeddedPlayer/v=2/album=789/", json_response["embed_url"]
  end

  test "should be publicly cacheable without a session cookie" do
    mock_html = <<~HTML
      <html>
        <head>
          <meta property="og:video" content="https://bandcamp.com/EmbeddedPlayer/v=2/album=123/"/>
        </head>
      </html>
    HTML

    URI.stubs(:open).with(bandcamp_url, uri_open_options).returns(StringIO.new(mock_html))

    get "/api/embeds/bandcamp", params: { url: bandcamp_url }

    assert_response :success
    assert_includes response.headers["Cache-Control"], "public"
    assert_nil response.headers["Set-Cookie"]
  end

  test "should not cache a missing og:video" do
    Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)
    URI.expects(:open).twice.with(bandcamp_url, uri_open_options).returns(StringIO.new("<html></html>"), StringIO.new("<html></html>"))

    2.times do
      get "/api/embeds/bandcamp", params: { url: bandcamp_url }
      assert_response :unprocessable_entity
    end
  end

  test "should cache resolved embed URLs" do
    Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)

    mock_html = <<~HTML
      <html>
        <head>
          <meta property="og:video" content="https://bandcamp.com/EmbeddedPlayer/v=2/album=789/"/>
        </head>
      </html>
    HTML

    URI.expects(:open).once.with(bandcamp_url, uri_open_options).returns(StringIO.new(mock_html))

    2.times do
      get "/api/embeds/bandcamp", params: { url: bandcamp_url }

      assert_response :success
      json_response = JSON.parse(response.body)
      assert_equal "https://bandcamp.com/EmbeddedPlayer/v=2/album=789/", json_response["embed_url"]
    end
  end

  test "should reject non-Bandcamp URLs" do
    URI.expects(:open).never

    get "/api/embeds/bandcamp", params: { url: "https://example.com/album" }

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal "Invalid Bandcamp URL", json_response["error"]
  end

  private

    def bandcamp_url
      "https://artist.bandcamp.com/album/example"
    end

    def uri_open_options
      {
        open_timeout: 2,
        read_timeout: 3
      }
    end
end
