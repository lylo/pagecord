require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.cache.store.clear
  end

  test "allows requests under the general throttle limit" do
    get "/", headers: { "HTTP_X_FORWARDED_FOR" => "1.2.3.4" }
    assert_response :success
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
