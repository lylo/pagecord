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

  test "throttles requests exceeding 300 req/min per IP" do
    300.times do
      get "/", headers: { "HTTP_X_FORWARDED_FOR" => "10.0.0.1" }
    end

    get "/", headers: { "HTTP_X_FORWARDED_FOR" => "10.0.0.1" }
    assert_equal 429, response.status
    assert_equal "Rate limit exceeded\n", response.body
  end

  test "throttles POST requests exceeding 30 req/min per IP" do
    30.times do
      post "/", headers: { "HTTP_X_FORWARDED_FOR" => "10.0.0.2" }
    end

    post "/", headers: { "HTTP_X_FORWARDED_FOR" => "10.0.0.2" }
    assert_equal 429, response.status
  end

  test "tracks different IPs independently" do
    30.times do
      post "/", headers: { "HTTP_X_FORWARDED_FOR" => "10.0.0.3" }
    end

    # Different IP should still be allowed
    post "/", headers: { "HTTP_X_FORWARDED_FOR" => "10.0.0.4" }
    assert_not_equal 429, response.status
  end

  test "safelists localhost requests" do
    301.times do
      get "/", headers: { "HTTP_X_FORWARDED_FOR" => "127.0.0.1" }
    end

    assert_response :success
  end

  test "safelists IPv6 localhost requests" do
    301.times do
      get "/", headers: { "HTTP_X_FORWARDED_FOR" => "::1" }
    end

    assert_response :success
  end
end
