require "test_helper"
require "mocha/minitest"

class CloudflareSaasApiTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
    @blog.update!(custom_domain: "example.com")
    @cloudflare_zone_id = ENV["CLOUDFLARE_ZONE_ID"]
    @cloudflare_api_token = ENV["CLOUDFLARE_API_TOKEN"]
    ENV["CLOUDFLARE_ZONE_ID"] = "zone-id"
    ENV["CLOUDFLARE_API_TOKEN"] = "token"
  end

  teardown do
    ENV["CLOUDFLARE_ZONE_ID"] = @cloudflare_zone_id
    ENV["CLOUDFLARE_API_TOKEN"] = @cloudflare_api_token
  end

  test "add domain stores existing custom hostname id without creating a duplicate" do
    expect_find_hostname("example.com", id: "root-id")
    expect_find_hostname("www.example.com", id: "www-id")
    HTTParty.expects(:post).never

    CloudflareSaasApi.new(@blog).add_domain("example.com")

    assert_equal "root-id", custom_hostname("example.com").external_id
    assert_equal "www-id", custom_hostname("www.example.com").external_id
  end

  test "add domain also stores apex hostname when canonical domain is www" do
    @blog.update!(custom_domain: "www.example.com")
    expect_find_hostname("www.example.com", id: "www-id")
    expect_find_hostname("example.com", id: "root-id")
    HTTParty.expects(:post).never

    CloudflareSaasApi.new(@blog).add_domain("www.example.com")

    assert_equal "www-id", custom_hostname("www.example.com").external_id
    assert_equal "root-id", custom_hostname("example.com").external_id
  end

  test "add domain ignores stale jobs after the blog domain changes" do
    @blog.update!(custom_domain: "new.example.com")
    HTTParty.expects(:get).never
    HTTParty.expects(:post).never

    CloudflareSaasApi.new(@blog).add_domain("example.com")

    assert_nil custom_hostname("example.com")
  end

  test "add domain transfers an existing hostname row to the current owner" do
    old_blog = blogs(:annie)
    old_blog.update!(custom_domain: nil)
    CloudflareCustomHostname.create!(blog: old_blog, domain: "example.com", external_id: "existing-id")
    expect_find_hostname("example.com", id: "existing-id")
    expect_find_hostname("www.example.com", id: "www-id")
    HTTParty.expects(:post).never

    CloudflareSaasApi.new(@blog).add_domain("example.com")

    assert_equal @blog, custom_hostname("example.com").blog
    assert_equal "existing-id", custom_hostname("example.com").external_id
  end

  test "remove domain deletes the old domain record without clearing a newer one" do
    @blog.update!(custom_domain: "new.example.com")
    CloudflareCustomHostname.create!(blog: @blog, domain: "example.com", external_id: "old-id")
    CloudflareCustomHostname.create!(blog: @blog, domain: "www.example.com", external_id: "old-www-id")
    CloudflareCustomHostname.create!(blog: @blog, domain: "new.example.com", external_id: "new-id")
    HTTParty.expects(:delete).with(
      "#{custom_hostnames_url}/old-id",
      headers: anything
    ).returns(response)
    HTTParty.expects(:delete).with(
      "#{custom_hostnames_url}/old-www-id",
      headers: anything
    ).returns(response)

    CloudflareSaasApi.new(@blog).remove_domain("example.com")

    assert_nil custom_hostname("example.com")
    assert_nil custom_hostname("www.example.com")
    assert_equal "new-id", custom_hostname("new.example.com").external_id
  end

  test "remove domain deletes stored apex and www hostname records" do
    @blog.update!(custom_domain: nil)
    CloudflareCustomHostname.create!(blog: @blog, domain: "example.com", external_id: "old-id")
    CloudflareCustomHostname.create!(blog: @blog, domain: "www.example.com", external_id: "www-id")
    HTTParty.expects(:delete).with(
      "#{custom_hostnames_url}/old-id",
      headers: anything
    ).returns(response)
    HTTParty.expects(:delete).with(
      "#{custom_hostnames_url}/www-id",
      headers: anything
    ).returns(response)

    CloudflareSaasApi.new(@blog).remove_domain("example.com")

    assert_nil custom_hostname("example.com")
    assert_nil custom_hostname("www.example.com")
  end

  test "remove domain keeps hostnames when the apex or www variant is still in use" do
    @blog.update!(custom_domain: "www.example.com")
    CloudflareCustomHostname.create!(blog: @blog, domain: "example.com", external_id: "root-id")
    CloudflareCustomHostname.create!(blog: @blog, domain: "www.example.com", external_id: "www-id")
    HTTParty.expects(:get).never
    HTTParty.expects(:delete).never

    CloudflareSaasApi.new(@blog).remove_domain("example.com")

    assert_equal "root-id", custom_hostname("example.com").external_id
    assert_equal "www-id", custom_hostname("www.example.com").external_id
  end

  test "remove domain can run after the blog has been destroyed" do
    @blog.update!(custom_domain: nil)
    CloudflareCustomHostname.where(domain: [ "example.com", "www.example.com" ]).destroy_all
    expect_find_hostname("example.com", id: "root-id")
    expect_find_hostname("www.example.com", id: "www-id")
    expect_delete_hostname("root-id")
    expect_delete_hostname("www-id")

    CloudflareSaasApi.new.remove_domain("example.com")
  end

  test "refresh domain validation patches pending hostnames" do
    CloudflareCustomHostname.create!(blog: @blog, domain: "example.com", external_id: "root-id")
    expect_fetch_hostname("root-id", result: pending_hostname("root-id", "example.com"))
    HTTParty.expects(:patch).with(
      "#{custom_hostnames_url}/root-id",
      headers: anything,
      body: { ssl: { method: "http", type: "dv", settings: { min_tls_version: "1.2" } } }.to_json
    ).returns(response(result: pending_hostname("root-id", "example.com")))

    refreshed_hostnames = CloudflareSaasApi.new(@blog).refresh_domain_validation("example.com")

    assert_equal [ "root-id" ], refreshed_hostnames.map { |hostname| hostname["id"] }
  end

  test "refresh domain validation does not patch active hostnames" do
    CloudflareCustomHostname.create!(blog: @blog, domain: "example.com", external_id: "root-id")
    expect_fetch_hostname("root-id", result: active_hostname("root-id", "example.com"))
    HTTParty.expects(:patch).never

    assert_empty CloudflareSaasApi.new(@blog).refresh_domain_validation("example.com")
  end

  test "refresh domain validation ignores stale domains" do
    @blog.update!(custom_domain: "new.example.com")
    CloudflareCustomHostname.create!(blog: @blog, domain: "example.com", external_id: "root-id")
    HTTParty.expects(:get).never
    HTTParty.expects(:patch).never

    assert_empty CloudflareSaasApi.new(@blog).refresh_domain_validation("example.com")
  end

  test "update domain patches stored hostnames" do
    CloudflareCustomHostname.create!(blog: @blog, domain: "example.com", external_id: "root-id")
    CloudflareCustomHostname.create!(blog: @blog, domain: "www.example.com", external_id: "www-id")
    expect_update_hostname("root-id", hostname: "example.com")
    expect_update_hostname("www-id", hostname: "www.example.com")

    hostnames = CloudflareSaasApi.new(@blog).update_domain("example.com")

    assert_equal [ "root-id", "www-id" ], hostnames.map { |hostname| hostname["id"] }
  end

  private

    def custom_hostnames_url
      "https://api.cloudflare.com/client/v4/zones/zone-id/custom_hostnames"
    end

    def expect_find_hostname(hostname, id:)
      HTTParty.expects(:get).with(
        custom_hostnames_url,
        headers: anything,
        query: { hostname: hostname }
      ).returns(response(result: [ { "id" => id, "hostname" => hostname } ]))
    end

    def expect_delete_hostname(id)
      HTTParty.expects(:delete).with(
        "#{custom_hostnames_url}/#{id}",
        headers: anything
      ).returns(response)
    end

    def expect_fetch_hostname(id, result:)
      HTTParty.expects(:get).with(
        "#{custom_hostnames_url}/#{id}",
        headers: anything
      ).returns(response(result: result))
    end

    def expect_update_hostname(id, hostname:)
      HTTParty.expects(:patch).with(
        "#{custom_hostnames_url}/#{id}",
        headers: anything,
        body: { ssl: { method: "http", type: "dv", settings: { min_tls_version: "1.2" } } }.to_json
      ).returns(response(result: pending_hostname(id, hostname)))
    end

    def custom_hostname(domain)
      CloudflareCustomHostname.find_by(domain:)
    end

    def pending_hostname(id, hostname)
      {
        "id" => id,
        "hostname" => hostname,
        "status" => "pending",
        "ssl" => { "status" => "pending_validation" }
      }
    end

    def active_hostname(id, hostname)
      {
        "id" => id,
        "hostname" => hostname,
        "status" => "active",
        "ssl" => { "status" => "active" }
      }
    end

    def response(code: 200, result: { "id" => "hostname-id", "hostname" => "example.com" }, errors: [])
      response = mock
      response.stubs(:success?).returns(code.between?(200, 299))
      response.stubs(:code).returns(code)
      response.stubs(:body).returns({ result:, errors: }.to_json)
      response.stubs(:parsed_response).returns({ "result" => result, "errors" => errors })
      response
    end
end
