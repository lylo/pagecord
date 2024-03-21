require "test_helper"

module AccessRequests
  class TokenDigestTest < ActiveSupport::TestCase
    test "generates a digest" do
      a = TokenDigest.new("mystring").digest
      b = TokenDigest.new("mystring").digest

      assert a.length > 10
      assert_equal a, b
    end
  end
end