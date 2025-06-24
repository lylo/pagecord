require "test_helper"
require "mocha/minitest"

class IpReputationTest < ActiveSupport::TestCase
  def setup
    @valid_ip = "1.1.1.1"
    @invalid_ip = "2.2.2.2"
    @blocked_country_ip = "3.3.3.3"
  end

  test "returns true for valid IP with no detections" do
    stub_valid_response
    assert IpReputation.valid?(@valid_ip)
  end

  test "returns true for IP with single detection" do
    stub_detected_response_1
    assert IpReputation.valid?(@invalid_ip)
  end

  test "returns false for IP with > 1 detection" do
    stub_detected_response_2
    assert_not IpReputation.valid?(@invalid_ip)
  end

  test "returns false for blocked country" do
    stub_blocked_country_response
    assert_not IpReputation.valid?(@blocked_country_ip)
  end

  test "returns true on API error" do
    IpReputation.stubs(:get).raises(HTTParty::Error)
    assert IpReputation.valid?(@valid_ip)
  end

  private

  def stub_valid_response
    response = mock
    response.stubs(:body).returns({
      success: true,
      data: {
        report: {
          blacklists: {
            engines: {
              "1" => { "detected" => false }
            }
          },
          information: {
            country_code: "US"
          }
        }
      }
    }.to_json)
    IpReputation.stubs(:get).returns(response)
  end

  def stub_detected_response_1
    response = mock
    response.stubs(:body).returns({
      success: true,
      data: {
        report: {
          blacklists: {
            engines: {
              "1" => { "detected" => true }
            }
          },
          information: {
            country_code: "US"
          }
        }
      }
    }.to_json)
    IpReputation.stubs(:get).returns(response)
  end

  def stub_detected_response_2
    response = mock
    response.stubs(:body).returns({
      success: true,
      data: {
        report: {
          blacklists: {
            engines: {
              "1" => { "detected" => true },
              "2" => { "detected" => true }
            }
          },
          information: {
            country_code: "US"
          }
        }
      }
    }.to_json)
    IpReputation.stubs(:get).returns(response)
  end

  def stub_blocked_country_response
    response = mock
    response.stubs(:body).returns({
      success: true,
      data: {
        report: {
          blacklists: {
            engines: {
              "1" => { "detected" => false },
              "2" => { "detected" => false }
            }
          },
          information: {
            country_code: "CN"
          }
        }
      }
    }.to_json)
    IpReputation.stubs(:get).returns(response)
  end
end
