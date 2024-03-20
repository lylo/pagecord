require "test_helper"

class UsernameTest < ActiveSupport::TestCase
  test "should be reserved" do
    Username::RESERVED.each do |username|
      assert Username.reserved?(username)
    end
  end

  test "should not be reserved" do
    refute Username.reserved?("olly")
    refute Username.reserved?("fred")
    refute Username.reserved?("joel")
  end
end
