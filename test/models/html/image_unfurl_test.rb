require "test_helper"
require "mocha/minitest"

class Html::ImageUnfurlTest < ActiveSupport::TestCase
  test "should unfurl image url from plain text" do
    FastImage.stubs(:size).returns([ 800, 600 ])
    FastImage.stubs(:type).returns(:jpeg)

    unfurl = Html::ImageUnfurl.new
    html = unfurl.transform("https://example.com/image.jpg")
    assert_equal "<img src=\"https://example.com/image.jpg\" pagecord=\"true\">", html
  end

  test "should unfurl image url from HTML" do
    FastImage.stubs(:size).returns([ 800, 600 ])
    FastImage.stubs(:type).returns(:jpeg)

    unfurl = Html::ImageUnfurl.new
    html = unfurl.transform("<div><a href=\"https://example.com/image.jpg\">https://example.com/image.jpg</a></div>")
    assert_equal "<div><img src=\"https://example.com/image.jpg\" pagecord=\"true\"></div>", html
  end

  test "should not unfurl enormous image" do
    FastImage.stubs(:size).returns([ 5001, 600 ])
    FastImage.stubs(:type).returns(:jpeg)

    unfurl = Html::ImageUnfurl.new
    html = unfurl.transform("<div><a href=\"https://example.com/image.jpg\">https://example.com/image.jpg</a></div>")
    assert_equal "<div><a href=\"https://example.com/image.jpg\">https://example.com/image.jpg</a></div>", html
  end

  test "should not unfurl unknown image type" do
    FastImage.stubs(:size).returns([ 800, 600 ])
    FastImage.stubs(:type).returns(:blah)

    unfurl = Html::ImageUnfurl.new
    html = unfurl.transform("<div><a href=\"https://example.com/image.jpg\">https://example.com/image.jpg</a></div>")
    assert_equal "<div><a href=\"https://example.com/image.jpg\">https://example.com/image.jpg</a></div>", html
  end
end
