require "test_helper"
require "mocha/minitest"

class Api::EmbedsControllerTest < ActionDispatch::IntegrationTest
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

    with_forgery_protection do
      post "/api/embeds/bandcamp", params: { url: bandcamp_url }
    end

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

    post "/api/embeds/bandcamp", params: { url: bandcamp_url }

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal "No og:video found", json_response["error"]
  end

  test "should handle network errors gracefully" do
    URI.stubs(:open).with(bandcamp_url, uri_open_options).raises(StandardError.new("Network error"))

    post "/api/embeds/bandcamp", params: { url: bandcamp_url }

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

    post "/api/embeds/bandcamp", params: { url: bandcamp_url }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "https://bandcamp.com/EmbeddedPlayer/v=2/album=456/", json_response["embed_url"]
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
      post "/api/embeds/bandcamp", params: { url: bandcamp_url }

      assert_response :success
      json_response = JSON.parse(response.body)
      assert_equal "https://bandcamp.com/EmbeddedPlayer/v=2/album=789/", json_response["embed_url"]
    end
  end

  test "should reject non-Bandcamp URLs" do
    URI.expects(:open).never

    post "/api/embeds/bandcamp", params: { url: "https://example.com/album" }

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal "Invalid Bandcamp URL", json_response["error"]
  end

  private

    def host_subdomain!(name)
      host! "#{name}.#{Rails.application.config.x.domain}"
    end

    def bandcamp_url
      "https://artist.bandcamp.com/album/example"
    end

    def uri_open_options
      {
        open_timeout: 2,
        read_timeout: 3
      }
    end

    def with_forgery_protection
      base_setting = ActionController::Base.allow_forgery_protection
      application_setting = ApplicationController.allow_forgery_protection

      ActionController::Base.allow_forgery_protection = true
      ApplicationController.allow_forgery_protection = true
      yield
    ensure
      ActionController::Base.allow_forgery_protection = base_setting
      ApplicationController.allow_forgery_protection = application_setting
    end
end
