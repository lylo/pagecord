require "test_helper"

class OpenGraphImageTest < ActiveSupport::TestCase
  setup do
    @post = posts(:one)
  end

  test "belongs to post" do
    og_image = OpenGraphImage.new(post: @post)
    assert_equal @post, og_image.post
  end

  test "can attach an image" do
    og_image = @post.create_open_graph_image!

    og_image.image.attach(
      io: StringIO.new("fake png data"),
      filename: "test.png",
      content_type: "image/png"
    )

    assert og_image.image.attached?
    assert_equal "test.png", og_image.image.filename.to_s
    assert_equal "image/png", og_image.image.content_type
  end

  test "can purge image" do
    og_image = @post.create_open_graph_image!

    og_image.image.attach(
      io: StringIO.new("fake png data"),
      filename: "test.png",
      content_type: "image/png"
    )

    assert og_image.image.attached?

    og_image.image.purge

    assert_not og_image.image.attached?
  end
end
