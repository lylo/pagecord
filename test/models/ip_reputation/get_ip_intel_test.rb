require "test_helper"
require "mocha/minitest"

class IpReputation::GetIpIntelTest < ActiveSupport::TestCase
  def setup
    @valid_ip = "1.1.1.1"
    @invalid_ip = "2.2.2.2"
  end

  test "returns true for a clean IP" do
    stub_get_ip_intel_response("0.0")
    assert IpReputation::GetIpIntel.valid?(@valid_ip)
  end

  test "returns false for a bad IP" do
    stub_get_ip_intel_response("0.99") # Boundary case
    assert_not IpReputation::GetIpIntel.valid?(@invalid_ip)

    stub_get_ip_intel_response("1.0")
    assert_not IpReputation::GetIpIntel.valid?(@invalid_ip)
  end

  test "returns true on API error" do
    HTTParty.stubs(:get).raises(HTTParty::Error)
    assert IpReputation::GetIpIntel.valid?(@valid_ip)
  end

  test "returns true on timeout errors" do
    HTTParty.stubs(:get).raises(Net::ReadTimeout)
    assert IpReputation::GetIpIntel.valid?(@valid_ip)

    HTTParty.stubs(:get).raises(Net::OpenTimeout)
    assert IpReputation::GetIpIntel.valid?(@valid_ip)

    HTTParty.stubs(:get).raises(Timeout::Error)
    assert IpReputation::GetIpIntel.valid?(@valid_ip)
  end

  test "returns true for non-numeric response (e.g., error message)" do
    stub_get_ip_intel_response("Your IP 127.0.0.1 has been blocked from using this service.")
    assert IpReputation::GetIpIntel.valid?(@valid_ip)
  end

  private

  def stub_get_ip_intel_response(body_content)
    response = mock
    response.stubs(:body).returns(body_content)
    HTTParty.stubs(:get).returns(response)
  end
end
