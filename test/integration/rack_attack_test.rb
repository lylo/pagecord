require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    # Freeze time so request counts can't straddle a throttle period boundary
    freeze_time

    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.cache.store.clear
  end

  test "throttles requests exceeding the general limit per IP" do
    Rack::Attack::GENERAL_LIMIT.times do
      get "/", headers: { "HTTP_X_FORWARDED_FOR" => "203.0.113.1" }
    end

    get "/", headers: { "HTTP_X_FORWARDED_FOR" => "203.0.113.1" }
    assert_equal 429, response.status
    assert_equal "Rate limit exceeded\n", response.body
  end

  test "throttles POST requests exceeding the POST limit per IP" do
    Rack::Attack::POST_LIMIT.times do
      post blog_page_views_url(host: blog_host), headers: { "HTTP_X_FORWARDED_FOR" => "203.0.113.2" }
    end

    post blog_page_views_url(host: blog_host), headers: { "HTTP_X_FORWARDED_FOR" => "203.0.113.2" }
    assert_equal 429, response.status
  end

  test "keeps /mcp requests with an invalid token on the IP throttle" do
    Rack::Attack::POST_LIMIT.times do |n|
      post mcp_url(host: "api.example.com"), params: { jsonrpc: "2.0", id: 1, method: "ping" }, as: :json,
        headers: { "HTTP_X_FORWARDED_FOR" => "203.0.113.5", "Authorization" => "Bearer bogus-#{n}" }
    end

    post mcp_url(host: "api.example.com"), params: { jsonrpc: "2.0", id: 1, method: "ping" }, as: :json,
      headers: { "HTTP_X_FORWARDED_FOR" => "203.0.113.5", "Authorization" => "Bearer bogus" }
    assert_equal 429, response.status
  end

  test "leaves /mcp requests with a valid token to the per-blog limit" do
    (Rack::Attack::POST_LIMIT + 1).times do
      post mcp_url(host: "api.example.com"), params: { jsonrpc: "2.0", id: 1, method: "ping" }, as: :json,
        headers: { "HTTP_X_FORWARDED_FOR" => "203.0.113.6", "Authorization" => "Bearer test_mcp_token" }
    end

    assert_response :success
  end

  test "tracks different IPs independently" do
    Rack::Attack::POST_LIMIT.times do
      post blog_page_views_url(host: blog_host), headers: { "HTTP_X_FORWARDED_FOR" => "203.0.113.3" }
    end

    post blog_page_views_url(host: blog_host), headers: { "HTTP_X_FORWARDED_FOR" => "203.0.113.4" }
    assert_not_equal 429, response.status
  end

  test "safelists localhost requests in non-production" do
    (Rack::Attack::GENERAL_LIMIT + 1).times do
      get "/", headers: { "HTTP_X_FORWARDED_FOR" => "127.0.0.1" }
    end

    assert_response :success
  end

  test "safelists IPv6 localhost requests in non-production" do
    (Rack::Attack::GENERAL_LIMIT + 1).times do
      get "/", headers: { "HTTP_X_FORWARDED_FOR" => "::1" }
    end

    assert_response :success
  end

  test "spoofed X-Forwarded-For leading with 127.0.0.1 does not bypass the throttle" do
    Rack::Attack::GENERAL_LIMIT.times do
      get "/", headers: { "HTTP_X_FORWARDED_FOR" => "127.0.0.1, 1.2.3.4" }
    end

    get "/", headers: { "HTTP_X_FORWARDED_FOR" => "127.0.0.1, 1.2.3.4" }
    assert_equal 429, response.status
  end

  test "localhost safelist does not apply in production" do
    Rails.env.stubs(:production?).returns(true)

    (Rack::Attack::GENERAL_LIMIT + 1).times do
      get "/", headers: { "HTTP_X_FORWARDED_FOR" => "127.0.0.1" }
    end

    assert_equal 429, response.status
  end

  test "spoofed RFC 7239 Forwarded header cannot rotate throttle identity" do
    Rails.env.stubs(:production?).returns(true)

    Rack::Attack::GENERAL_LIMIT.times do |index|
      get "/", headers: {
        "HTTP_FORWARDED" => "for=198.51.100.#{index}",
        "HTTP_X_FORWARDED_FOR" => "203.0.113.9"
      }
    end

    get "/", headers: {
      "HTTP_FORWARDED" => "for=198.51.100.99",
      "HTTP_X_FORWARDED_FOR" => "203.0.113.9"
    }
    assert_equal 429, response.status
  end

  private

    def blog_host
      "#{blogs(:joel).subdomain}.#{Rails.application.config.x.domain}"
    end
end
