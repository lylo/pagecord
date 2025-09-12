require "test_helper"

class TrimmableTest < ActiveSupport::TestCase
  test "should strip empty tags before save" do
    post = posts(:two)
    post.content = "<div><br><p>Test</p><img src='test.jpg'><br><br>hello\n<br><div></div>\n\n\n</div><p></p><div></div>"
    post.save!

    assert_equal "<div><br><p>Test</p><img src=\"test.jpg\"><br><br>hello</div>", post.content.to_s.gsub("\n", "")
  end

  test "should remove trailing <br> tags" do
    post = posts(:two)
    post.content = "<div>this is some text</div><br><br><br>"
    post.save!

    assert_equal "<div>this is some text</div>", post.content.to_s.strip
  end

  test "should remove trailing <br> tags within div" do
    post = posts(:two)
    post.content = "<div>this is some text</div><br><br><div>this is more text<br><br><br></div>"
    post.save!

    assert_equal "<div>this is some text</div><br><br><div>this is more text</div>", post.content.to_s.strip
  end

  test "should remove trailing <br> tags within div and p" do
    post = posts(:two)
    post.content = "<div><p>this is some text<br><br>this is more text<br><br><br></p></div>"
    post.save!

    assert_equal "<div><p>this is some text<br><br>this is more text</p></div>", post.content.to_s.strip
  end

  test "should remove empty divs after hashtag extraction" do
    post = posts(:two)
    post.content = "<div>This is a test</div><div><br></div><div></div>"
    post.save!

    assert_equal "<div>This is a test</div>", post.content.to_s.strip
  end

  test "should not remove divs with actual content" do
    post = posts(:two)
    post.content = "<div>This is a test</div><div><span>Keep this</span></div><div>And this</div>"
    post.save!

    assert_equal "<div>This is a test</div><div><span>Keep this</span></div><div>And this</div>", post.content.to_s.strip
  end

  test "should not remove divs with images or other elements" do
    post = posts(:two)
    post.content = "<div>This is a test</div><div><img src='test.jpg'></div><div><br></div><div></div>"
    post.save!

    assert_equal "<div>This is a test</div><div><img src=\"test.jpg\"></div>", post.content.to_s.strip
  end

  test "should remove divs with multiple br tags" do
    post = posts(:two)
    post.content = "<div>This is a test</div><div><br><br><br></div><div><br></div><div></div>"
    post.save!

    assert_equal "<div>This is a test</div>", post.content.to_s.strip
  end

  test "should not remove divs with br tags followed by content" do
    post = posts(:two)
    post.content = "<div>This is a test</div><div><br><br>Keep this content</div><div><br></div><div></div>"
    post.save!

    assert_equal "<div>This is a test</div><div><br><br>Keep this content</div>", post.content.to_s.strip.gsub("\n", "")
  end

  test "should not remove divs with content followed by br tags" do
    post = posts(:two)
    post.content = "<div>This is a test</div><div>Keep this content<br><br></div><div><br></div><div></div>"
    post.save!

    assert_equal "<div>This is a test</div><div>Keep this content</div>", post.content.to_s.strip
  end
end
