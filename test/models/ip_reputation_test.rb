require "test_helper"
require "mocha/minitest"

class IpReputationTest < ActiveSupport::TestCase
  def setup
    @valid_ip = "1.1.1.1"

    # Reset provider to default before each test
    IpReputation.provider = nil
  end

  def teardown
    # Ensure provider is reset after each test
    IpReputation.provider = nil
  end

  test "provider defaults to GetIpIntel" do
    assert_equal IpReputation::GetIpIntel, IpReputation.provider
  end

  test "valid? delegates to the default provider (GetIpIntel)" do
    IpReputation::GetIpIntel.expects(:valid?).with(@valid_ip).returns(true)
    assert IpReputation.valid?(@valid_ip)
  end

  test "valid? delegates to the configured provider (ApiVoid)" do
    IpReputation.provider = IpReputation::ApiVoid
    IpReputation::ApiVoid.expects(:valid?).with(@valid_ip).returns(true)
    assert IpReputation.valid?(@valid_ip)
  end
end
