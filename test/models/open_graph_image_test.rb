require 'test_helper'

class OpenGraphImageTest < ActiveSupport::TestCase
  setup do
    @post = posts(:one)
  end

  test "should create open graph image from post with image" do
    @post.body = "<img pagecord=\"true\" src=\"http://example.com/image.jpg\">"
    open_graph_image = OpenGraphImage.from_post(@post)
    assert open_graph_image.valid?
    assert_equal "http://example.com/image.jpg", open_graph_image.url
  end

  test "should not create open graph image from post without image" do
    @post.body = "<p>No image here</p>"
    open_graph_image = OpenGraphImage.from_post(@post)
    assert_nil open_graph_image
  end
end