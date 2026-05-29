require "test_helper"

class Html::EmailMediaPreviewTest < ActiveSupport::TestCase
  test "replaces bare youtube watch links with linked thumbnails" do
    html = %(<p><a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ">https://www.youtube.com/watch?v=dQw4w9WgXcQ</a></p>)
    result = Html::EmailMediaPreview.new.transform(html)

    assert_includes result, %(<a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ" style="display:block;text-align:center;">)
    assert_includes result, %(<img src="https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg")
    assert_includes result, %(alt="YouTube video thumbnail")
    assert_includes result, %(style="display:block;margin:0 auto;max-width:100%;height:auto;")
  end

  test "replaces standalone youtube text urls with linked thumbnails" do
    html = %(<p>https://www.youtube.com/watch?v=dQw4w9WgXcQ</p>)
    result = Html::EmailMediaPreview.new.transform(html)

    assert_includes result, %(<a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ" style="display:block;text-align:center;">)
    assert_includes result, %(<img src="https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg")
  end

  test "leaves inline youtube text urls unchanged" do
    html = %(<p>Watch https://www.youtube.com/watch?v=dQw4w9WgXcQ later</p>)
    result = Html::EmailMediaPreview.new.transform(html)

    assert_includes result, "Watch https://www.youtube.com/watch?v=dQw4w9WgXcQ later"
    assert_not_includes result, "hqdefault.jpg"
  end

  test "supports youtu be live and shorts urls" do
    urls = [
      "https://youtu.be/dQw4w9WgXcQ",
      "https://youtube.com/live/dQw4w9WgXcQ",
      "https://www.youtube.com/shorts/dQw4w9WgXcQ"
    ]

    urls.each do |url|
      result = Html::EmailMediaPreview.new.transform(%(<p><a href="#{url}">#{url}</a></p>))

      assert_includes result, %(<img src="https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg")
    end
  end

  test "replaces youtube links when text omits query string" do
    html = %(<p><a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ">https://www.youtube.com/watch</a></p>)
    result = Html::EmailMediaPreview.new.transform(html)

    assert_includes result, %(<img src="https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg")
  end

  test "leaves editorial youtube links unchanged" do
    html = %(<p><a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ">watch this</a></p>)
    result = Html::EmailMediaPreview.new.transform(html)

    assert_includes result, ">watch this</a>"
    assert_not_includes result, "hqdefault.jpg"
  end

  test "does not create nested links" do
    html = %(<p><a href="https://example.com">https://www.youtube.com/watch?v=dQw4w9WgXcQ</a></p>)
    result = Html::EmailMediaPreview.new.transform(html)

    assert_equal 1, Nokogiri::HTML::DocumentFragment.parse(result).css("a").count
    assert_not_includes result, "hqdefault.jpg"
  end

  test "leaves non-youtube media links unchanged" do
    html = %(<p><a href="https://open.spotify.com/track/abc123">https://open.spotify.com/track/abc123</a></p>)
    result = Html::EmailMediaPreview.new.transform(html)

    assert_includes result, "https://open.spotify.com/track/abc123"
    assert_not_includes result, "<img"
  end

  test "leaves unsupported youtube urls unchanged" do
    html = %(<p><a href="https://www.youtube.com/channel/example">https://www.youtube.com/channel/example</a></p>)
    result = Html::EmailMediaPreview.new.transform(html)

    assert_includes result, "https://www.youtube.com/channel/example"
    assert_not_includes result, "hqdefault.jpg"
  end
end
