require "test_helper"

class SubdomainTest < ActiveSupport::TestCase
  test "should be reserved" do
    Subdomain::RESERVED.each do |subdomain|
      assert Subdomain.reserved?(subdomain)
    end
  end

  test "should not be reserved" do
    assert_not Subdomain.reserved?("olly")
    assert_not Subdomain.reserved?("fred")
    assert_not Subdomain.reserved?("joel")
  end

  test "should not allow full stops" do
    assert_not Subdomain.valid_format?("joel.murphy")
  end

  test "should not allow underscores" do
    assert_not Subdomain.valid_format?("joel_murphy")
    assert_not Subdomain.valid_format?("joel_murphy_")
  end
end
