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
    HTTParty.expects(:get).with(
      custom_hostnames_url,
      headers: anything,
      query: { hostname: "example.com" },
      timeout: CloudflareSaasApi::REQUEST_TIMEOUT
    ).returns(response(result: [ { "id" => "existing-id", "hostname" => "example.com" } ]))
    HTTParty.expects(:post).never

    CloudflareSaasApi.new(@blog).add_domain("example.com")

    assert_equal "existing-id", custom_hostname("example.com").external_id
  end

  test "add domain ignores stale jobs after the blog domain changes" do
    @blog.update!(custom_domain: "new.example.com")
    HTTParty.expects(:get).never
    HTTParty.expects(:post).never

    CloudflareSaasApi.new(@blog).add_domain("example.com")

    assert_nil custom_hostname("example.com")
  end

  test "remove domain deletes the old domain record without clearing a newer one" do
    @blog.update!(custom_domain: "new.example.com")
    CloudflareCustomHostname.create!(blog: @blog, domain: "example.com", external_id: "old-id")
    CloudflareCustomHostname.create!(blog: @blog, domain: "new.example.com", external_id: "new-id")
    HTTParty.expects(:delete).with(
      "#{custom_hostnames_url}/old-id",
      headers: anything,
      timeout: CloudflareSaasApi::REQUEST_TIMEOUT
    ).returns(response)

    CloudflareSaasApi.new(@blog).remove_domain("example.com")

    assert_nil custom_hostname("example.com")
    assert_equal "new-id", custom_hostname("new.example.com").external_id
  end

  test "remove domain deletes the stored hostname record" do
    @blog.update!(custom_domain: nil)
    CloudflareCustomHostname.create!(blog: @blog, domain: "example.com", external_id: "old-id")
    HTTParty.expects(:delete).with(
      "#{custom_hostnames_url}/old-id",
      headers: anything,
      timeout: CloudflareSaasApi::REQUEST_TIMEOUT
    ).returns(response)

    CloudflareSaasApi.new(@blog).remove_domain("example.com")

    assert_nil custom_hostname("example.com")
  end

  test "status returns nil on Cloudflare timeouts" do
    CloudflareCustomHostname.create!(blog: @blog, domain: "example.com", external_id: "hostname-id")
    HTTParty.expects(:get).raises(Net::ReadTimeout)

    assert_nil CloudflareSaasApi.new(@blog).status
  end

  private

    def custom_hostnames_url
      "https://api.cloudflare.com/client/v4/zones/zone-id/custom_hostnames"
    end

    def custom_hostname(domain)
      CloudflareCustomHostname.find_by(blog: @blog, domain:)
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
