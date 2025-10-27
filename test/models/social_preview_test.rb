# frozen_string_literal: true

require "test_helper"

class SocialPreviewTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
    @post = posts(:one)
    @post.update!(blog: @blog, title: "Test Post Title")
  end

  test "generates SVG output" do
    preview = SocialPreview.new(@post)
    svg = preview.to_svg

    assert_includes svg, "<svg"
    assert_includes svg, "xmlns=\"http://www.w3.org/2000/svg\""
    assert_includes svg, "width=\"1200\""
    assert_includes svg, "height=\"630\""
  end

  test "generates PNG output" do
    preview = SocialPreview.new(@post)
    png = preview.to_png

    assert png.is_a?(String)
    assert png.bytesize > 0
    # PNG magic number
    assert_equal "\x89PNG".b, png[0..3].b
  end

  test "includes post title in SVG" do
    @post.update!(title: "My Amazing Post")
    preview = SocialPreview.new(@post)
    svg = preview.to_svg

    assert_includes svg, "My Amazing Post"
  end

  test "includes blog name in SVG" do
    @blog.update!(subdomain: "testblog")
    preview = SocialPreview.new(@post)
    svg = preview.to_svg

    assert_includes svg, "@testblog"
  end

  test "escapes HTML entities correctly" do
    @post.update!(title: "What I've learned about <testing>")
    preview = SocialPreview.new(@post)
    svg = preview.to_svg

    # Should escape < and >
    assert_includes svg, "&lt;testing&gt;"
    # Rails' h() helper escapes apostrophes as &#39; which is fine for SVG
    assert svg.include?("What I've learned about") || svg.include?("What I&#39;ve learned about")
  end

  test "wraps long titles across multiple lines" do
    @post.update!(title: "This is a very long title that should definitely wrap across multiple lines in the preview")
    preview = SocialPreview.new(@post)
    svg = preview.to_svg

    # Should have multiple <text> elements for title lines
    assert svg.scan(/<text/).count > 2 # At least 2+ text elements (title lines + blog name)
  end

  test "limits title to 3 lines maximum" do
    @post.update!(title: "A " * 100) # Very long title
    preview = SocialPreview.new(@post)
    lines = preview.send(:wrap_title)

    assert_operator lines.length, :<=, 3
  end

  test "includes favicon when blog has avatar" do
    @blog.avatar.attach(
      io: StringIO.new("fake image data"),
      filename: "avatar.png",
      content_type: "image/png"
    )

    preview = SocialPreview.new(@post)
    svg = preview.to_svg

    assert_includes svg, "<image href="
    assert_includes svg, "data:image/png;base64"
  end

  test "uses default favicon when blog has no avatar" do
    @blog.avatar.purge if @blog.avatar.attached?

    preview = SocialPreview.new(@post)
    svg = preview.to_svg

    assert_includes svg, "<image href="
    assert_includes svg, "data:image/svg+xml;base64"
  end

  test "uses display_title when post has no title" do
    @post.update!(title: nil)
    preview = SocialPreview.new(@post)
    svg = preview.to_svg

    # Should use text_summary (truncated to 64 chars in display_title) or "Untitled"
    # The fixture has content so should show truncated text_summary
    assert svg.include?("Street photography") || svg.include?("Untitled")
  end

  test "font_family returns correct font stack" do
    @blog.update!(font: "serif")
    preview = SocialPreview.new(@post)
    assert_includes preview.send(:font_family), "Lora"

    @blog.update!(font: "mono")
    preview = SocialPreview.new(@post)
    assert_includes preview.send(:font_family), "IBM Plex Mono"

    @blog.update!(font: "sans")
    preview = SocialPreview.new(@post)
    assert_includes preview.send(:font_family), "InterVariable"
  end
end
