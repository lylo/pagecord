require "test_helper"

class TrimmableTest < ActiveSupport::TestCase
  test "should strip empty tags before save" do
    post = posts(:two)
    post.content = "<div><br><p>Test</p><img src='test.jpg'><br><br>hello\n<br><div></div>\n\n\n</div><p></p><div></div>"
    post.save!

    assert_equal "<div data-controller=\"syntax-highlight\" class=\"lexxy-content\">  <div class=\"lexxy-content\">  <div><br><p>Test</p><img src=\"test.jpg\"><br><br>hello</div></div></div>", post.content.to_s.gsub("\n", "")
  end

  test "should remove trailing <br> tags" do
    post = posts(:two)
    post.content = "<div>this is some text</div><br><br><br>"
    post.save!

    assert_equal "<div data-controller=\"syntax-highlight\" class=\"lexxy-content\">\n  <div class=\"lexxy-content\">\n  <div>this is some text</div></div>\n</div>", post.content.to_s.strip
  end

  test "should remove trailing <br> tags within div" do
    post = posts(:two)
    post.content = "<div>this is some text</div><br><br><div>this is more text<br><br><br></div>"
    post.save!

    assert_equal "<div data-controller=\"syntax-highlight\" class=\"lexxy-content\">\n  <div class=\"lexxy-content\">\n  <div>this is some text</div><br><br><div>this is more text</div></div>\n</div>", post.content.to_s.strip
  end

  test "should remove trailing <br> tags within div and p" do
    post = posts(:two)
    post.content = "<div><p>this is some text<br><br>this is more text<br><br><br></p></div>"
    post.save!

    assert_equal "<div data-controller=\"syntax-highlight\" class=\"lexxy-content\">\n  <div class=\"lexxy-content\">\n  <div><p>this is some text<br><br>this is more text</p></div></div>\n</div>", post.content.to_s.strip
  end

  test "should remove empty divs after hashtag extraction" do
    post = posts(:two)
    post.content = "<div>This is a test</div><div><br></div><div></div>"
    post.save!

    assert_equal "<div data-controller=\"syntax-highlight\" class=\"lexxy-content\">\n  <div class=\"lexxy-content\">\n  <div>This is a test</div></div>\n</div>", post.content.to_s.strip
  end

  test "should not remove divs with actual content" do
    post = posts(:two)
    post.content = "<div>This is a test</div><div><span>Keep this</span></div><div>And this</div>"
    post.save!

    assert_equal "<div data-controller=\"syntax-highlight\" class=\"lexxy-content\">\n  <div class=\"lexxy-content\">\n  <div>This is a test</div><div><span>Keep this</span></div><div>And this</div></div>\n</div>", post.content.to_s.strip
  end

  test "should not remove divs with images or other elements" do
    post = posts(:two)
    post.content = "<div>This is a test</div><div><img src='test.jpg'></div><div><br></div><div></div>"
    post.save!

    assert_equal "<div data-controller=\"syntax-highlight\" class=\"lexxy-content\">\n  <div class=\"lexxy-content\">\n  <div>This is a test</div><div><img src=\"test.jpg\"></div></div>\n</div>", post.content.to_s.strip
  end

  test "should remove divs with multiple br tags" do
    post = posts(:two)
    post.content = "<div>This is a test</div><div><br><br><br></div><div><br></div><div></div>"
    post.save!

    assert_equal "<div data-controller=\"syntax-highlight\" class=\"lexxy-content\">\n  <div class=\"lexxy-content\">\n  <div>This is a test</div></div>\n</div>", post.content.to_s.strip
  end

  test "should not remove divs with br tags followed by content" do
    post = posts(:two)
    post.content = "<div>This is a test</div><div><br><br>Keep this content</div><div><br></div><div></div>"
    post.save!

    assert_equal "<div data-controller=\"syntax-highlight\" class=\"lexxy-content\">  <div class=\"lexxy-content\">  <div>This is a test</div><div><br><br>Keep this content</div></div></div>", post.content.to_s.strip.gsub("\n", "")
  end

  test "should not remove divs with content followed by br tags" do
    post = posts(:two)
    post.content = "<div>This is a test</div><div>Keep this content<br><br></div><div><br></div><div></div>"
    post.save!

    assert_equal "<div data-controller=\"syntax-highlight\" class=\"lexxy-content\">\n  <div class=\"lexxy-content\">\n  <div>This is a test</div><div>Keep this content</div></div>\n</div>", post.content.to_s.strip
  end
end
