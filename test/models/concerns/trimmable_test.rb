require "test_helper"

class TrimmableTest < ActiveSupport::TestCase

  test "should strip empty tags before save" do
    post = posts(:two)
    post.content = "<div><br><p>Test</p><br><br>\n<p><br></p><br><div></div>\n\n\n</div>"
    post.save!
    assert_equal "<div><br><p>Test</p></div>", post.content.to_s.gsub("\n", "")
  end
end
