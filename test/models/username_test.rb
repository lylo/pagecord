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

  test "should not allow full stops" do
    assert_not Username.valid_format?("joel.murphy")
  end

  test "should not allow underscores" do
    assert_not Username.valid_format?("joel_murphy")
    assert_not Username.valid_format?("joel_murphy_")
  end
end
