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

  test "is enqueued when a pdf is embedded in a post" do
    assert_enqueued_with job: GeneratePreviewJob do
      create_post_embedding(@blob)
    end
  end

  test "is enqueued when a video is embedded in a post" do
    ActiveStorage::Blob.any_instance.stubs(:previewable?).returns(true)
    video = ActiveStorage::Blob.create_and_upload!(io: file_fixture("tiny.jpg").open, filename: "clip.mp4", content_type: "video/mp4", identify: false)

    assert_enqueued_with job: GeneratePreviewJob do
      create_post_embedding(video)
    end
  end

  test "is not enqueued for an image" do
    image = create_image_blob

    assert_no_enqueued_jobs only: GeneratePreviewJob do
      create_post_embedding(image)
    end
  end

  private

    def create_post_embedding(blob)
      blogs(:joel).posts.create!(title: "Attached", content: attachment_node_for(blob), status: :published)
    end
end
