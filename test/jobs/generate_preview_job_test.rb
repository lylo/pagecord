require "test_helper"

class GeneratePreviewJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @blob = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("document.pdf").open,
      filename: "document.pdf",
      content_type: "application/pdf"
    )
  end

  test "renders the first page to an attached preview image" do
    GeneratePreviewJob.perform_now(@blob)

    assert @blob.reload.preview_image.attached?
    assert_equal "image/png", @blob.preview_image.content_type
  end

  test "does nothing when a preview already exists" do
    GeneratePreviewJob.perform_now(@blob)
    existing = @blob.reload.preview_image.blob

    GeneratePreviewJob.perform_now(@blob)

    assert_equal existing, @blob.reload.preview_image.blob
  end

  test "does nothing without a previewer" do
    @blob.stubs(:previewable?).returns(false)

    GeneratePreviewJob.perform_now(@blob)

    assert_not @blob.reload.preview_image.attached?
  end

  test "is enqueued when a pdf is uploaded" do
    assert_enqueued_with job: GeneratePreviewJob do
      ActiveStorage::Blob.create_and_upload!(io: file_fixture("document.pdf").open, filename: "document.pdf", content_type: "application/pdf")
    end
  end

  test "is enqueued when a video is uploaded" do
    ActiveStorage::Blob.any_instance.stubs(:previewable?).returns(true)

    assert_enqueued_with job: GeneratePreviewJob do
      ActiveStorage::Blob.create_and_upload!(io: file_fixture("tiny.jpg").open, filename: "clip.mp4", content_type: "video/mp4", identify: false)
    end
  end

  test "is not enqueued for an image" do
    assert_no_enqueued_jobs only: GeneratePreviewJob do
      create_image_blob
    end
  end

  test "retries until a direct upload arrives" do
    blob = ActiveStorage::Blob.create_before_direct_upload!(filename: "document.pdf", byte_size: 1.kilobyte, checksum: "abc123", content_type: "application/pdf")

    assert_enqueued_with job: GeneratePreviewJob, args: [ blob ] do
      GeneratePreviewJob.perform_now(blob)
    end
  end
end
