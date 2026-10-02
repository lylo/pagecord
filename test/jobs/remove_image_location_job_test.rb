require "test_helper"

class RemoveImageLocationJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "removes GPS and XMP but keeps the orientation and camera" do
    blob = upload "gps.jpg"

    assert_no_enqueued_jobs only: RemoveImageLocationJob do
      RemoveImageLocationJob.perform_now(blob)
    end

    blob.reload.open do |file|
      image = Vips::Image.new_from_file(file.path)
      assert_empty image.get_fields.grep(/\Aexif-ifd3-|\Axmp-data\z/)
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

  test "is enqueued once a photo is analysed" do
    blob = upload "gps.jpg"

    assert_enqueued_with job: RemoveImageLocationJob, args: [ blob ] do
      blob.analyze
    end
  end

  private

    def upload(fixture)
      ActiveStorage::Blob.create_and_upload!(io: file_fixture(fixture).open, filename: fixture, content_type: "image/jpeg")
    end
end
