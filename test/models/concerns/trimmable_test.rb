require "test_helper"

class TrimmableTest < ActiveSupport::TestCase

  test "should strip empty tags before save" do
    post = posts(:two)
    post.content = "<div><br><p>Test</p><img src='test.jpg'><br><br>hello\n<br><div></div>\n\n\n</div><p></p><div></div>"
    post.save!
    assert_equal "<div><br><p>Test</p><img src=\"test.jpg\"><br><br>hello<br><div></div></div>", post.content.to_s.gsub("\n", "")
  end
end
