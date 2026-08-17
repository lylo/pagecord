require "test_helper"

class SuspiciousEmailTest < ActiveSupport::TestCase
  # Real examples from production logs
  test "flags machine generated dotted gmail addresses" do
    [
      "z.oz.or.i.po.b.634@gmail.com",
      "a.v.o.j.o.v.et.ugu.008@gmail.com",
      "huq.e.gez.1.27@gmail.com"
    ].each do |email|
      assert SuspiciousEmail.new(email).suspicious?, "expected #{email} to be suspicious"
    end
  end

  test "allows ordinary gmail addresses" do
    [ "joel@gmail.com", "first.last@gmail.com", "joel.j.spolsky@gmail.com" ].each do |email|
      assert_not SuspiciousEmail.new(email).suspicious?, "expected #{email} to be allowed"
    end
  end

  test "ignores dots outside gmail" do
    assert_not SuspiciousEmail.new("a.b.c.d.e@example.com").suspicious?
  end

  test "handles blank and malformed addresses" do
    [ nil, "", "not-an-email" ].each do |email|
      assert_not SuspiciousEmail.new(email).suspicious?
    end
  end
end
