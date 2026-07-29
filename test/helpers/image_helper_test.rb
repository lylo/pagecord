require "test_helper"

class ImageHelperTest < ActionView::TestCase
  include ImageHelper

  setup do
    Rails.configuration.x.cloudflare_image_resizing = true
    @blob = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("space.jpg").open, filename: "space.jpg", content_type: "image/jpeg"
    )
  end

  teardown do
    Rails.configuration.x.cloudflare_image_resizing = nil
  end

  test "uses Cloudflare for an image within its limits" do
    @blob.update!(metadata: { "width" => 4000, "height" => 3000 })

    assert_includes resized_image_url(@blob, width: 1600, height: 1200), "/cdn-cgi/image/"
  end

  # Cloudflare answers error 9413 rather than an image, so the post renders a
  # broken one. 8736x11648 is the photo that first hit this.
  test "falls back to a variant for an image over the Cloudflare area limit" do
    @blob.update!(metadata: { "width" => 8736, "height" => 11648 })

    assert_not_includes resized_image_url(@blob, width: 1600, height: 1200), "/cdn-cgi/image/"
  end

  test "falls back to a variant for an image over the Cloudflare dimension limit" do
    @blob.update!(metadata: { "width" => 60_000, "height" => 100 })

    assert_not_includes resized_image_url(@blob, width: 1600, height: 1200), "/cdn-cgi/image/"
  end

  test "uses Cloudflare when the blob has not been analysed" do
    @blob.update!(metadata: {})

    assert_includes resized_image_url(@blob, width: 1600, height: 1200), "/cdn-cgi/image/"
  end
end
