require "test_helper"

class UsernameTest < ActiveSupport::TestCase
  test "should be reserved" do
    Username::RESERVED.each do |username|
      assert Username.reserved?(username)
    end
  end

  test "should not be reserved" do
    assert_not Username.reserved?("olly")
    assert_not Username.reserved?("fred")
    assert_not Username.reserved?("joel")
  end

  test "should allow a single full stop, but not at the start or end" do
    assert Username.valid_format?("joel.murphy")

    assert_not Username.valid_format?("joel..murphy")
    assert_not Username.valid_format?(".joelmurphy")
    assert_not Username.valid_format?(".joelmurphy.")
    assert_not Username.valid_format?("joelmurphy.")

    assert Username.valid_format?("joelmurphy_")
    assert Username.valid_format?("_joelmurphy")
    assert Username.valid_format?("joel_murphy")
    assert_not Username.valid_format?("joelmurphy__")
  end
end
