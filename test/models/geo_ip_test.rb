require "test_helper"
require "mocha/minitest"

class GeoIpTest < ActiveSupport::TestCase
  test "returns nil when database file does not exist" do
    File.stubs(:exist?).with(GeoIp::DB_PATH).returns(false)
    assert_nil GeoIp.lookup("8.8.8.8")
  end

  test "returns nil on lookup error" do
    db = stub(lookup: nil)
    db.stubs(:lookup).raises(StandardError.new("bad"))
    GeoIp.stubs(:db).returns(db)
    File.stubs(:exist?).with(GeoIp::DB_PATH).returns(true)

    assert_nil GeoIp.lookup("invalid")
  end
end
