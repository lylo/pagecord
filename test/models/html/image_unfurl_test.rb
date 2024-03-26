require "test_helper"

class Html::ImageUnfurlTest < ActiveSupport::TestCase
  test "should unfurl image url from plain text" do
    unfurl = Html::ImageUnfurl.new
    html = unfurl.transform("https://example.com/image.jpg")
    assert_equal "<img src=\"https://example.com/image.jpg\" pagecord=\"true\">", html
  end

  test "should unfurl image url from HTML" do
    unfurl = Html::ImageUnfurl.new
    html = unfurl.transform("<div><a href=\"https://example.com/image.jpg\">https://example.com/image.jpg</a></div>")
    assert_equal "<div><img src=\"https://example.com/image.jpg\" pagecord=\"true\"></div>", html
  end
end
