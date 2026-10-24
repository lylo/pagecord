require "test_helper"

class SubdomainTest < ActiveSupport::TestCase
  test "should not allow full stops" do
    assert_not Subdomain.valid_format?("joel.murphy")
  end

  test "should not allow underscores" do
    assert_not Subdomain.valid_format?("joel_murphy")
    assert_not Subdomain.valid_format?("joel_murphy_")
  end
end
