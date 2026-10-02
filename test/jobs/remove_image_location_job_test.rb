require "test_helper"

class RemoveImageLocationJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "removes GPS but keeps the orientation, camera and other XMP" do
    blob = upload "gps.jpg"

    assert_no_enqueued_jobs only: RemoveImageLocationJob do
      RemoveImageLocationJob.perform_now(blob)
    end

    blob.reload.open do |file|
      image = Vips::Image.new_from_file(file.path)
      assert_empty image.get_fields.grep(/\Aexif-ifd3-/)
      assert_no_match "GPSLatitude", image.get("xmp-data")
      assert_match "London", image.get("xmp-data")
      assert_equal 6, image.get("orientation")
      assert_match "TestCam", image.get("exif-ifd0-Model")
    end
    assert_equal blob.service.compute_checksum(StringIO.new(blob.download)), blob.checksum
  end

  test "leaves a photo without location untouched" do
    blob = upload "tiny.jpg"
    ActiveStorage::Blob.any_instance.expects(:upload).never

    RemoveImageLocationJob.perform_now(blob)
  end

  test "leaves files that aren't photos alone" do
    blob = ActiveStorage::Blob.create_and_upload!(io: file_fixture("document.pdf").open, filename: "document.pdf", content_type: "application/pdf")
    Open3.expects(:capture3).never

    RemoveImageLocationJob.perform_now(blob)
  end

  test "reads a photo whose filename doesn't match its format" do
    blob = ActiveStorage::Blob.create_and_upload!(io: file_fixture("baby-yoda.webp").open, filename: "photo.jpg", content_type: "image/webp")

    assert_nothing_raised { RemoveImageLocationJob.perform_now(blob) }
  end

  test "gives up on a file exiftool can't write" do
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("not an image"), filename: "broken.jpg", content_type: "image/jpeg", identify: false)

    assert_nothing_raised { RemoveImageLocationJob.perform_now(blob) }
    assert_equal "not an image", blob.reload.download
  end

  test "is enqueued when an avatar is uploaded" do
    blog = blogs(:joel)

    blog.update!(avatar: Rack::Test::UploadedFile.new(file_fixture("gps.jpg"), "image/jpeg"))

    assert_enqueued_with job: RemoveImageLocationJob, args: [ blog.avatar.blob ]
  end

  test "is enqueued when an uploaded photo is added to a post" do
    blob = upload "gps.jpg"

    posts(:one).update!(content: ActionText::Content.new("").append_attachables(blob).to_s)

    assert_enqueued_with job: RemoveImageLocationJob, args: [ blob ]
  end

  private

    def upload(fixture)
      ActiveStorage::Blob.create_and_upload!(io: file_fixture(fixture).open, filename: fixture, content_type: "image/jpeg")
    end
end
