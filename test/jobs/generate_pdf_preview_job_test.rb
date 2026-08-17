require "test_helper"

class GeneratePdfPreviewJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @blob = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("document.pdf").open,
      filename: "document.pdf",
      content_type: "application/pdf"
    )
  end

  test "renders the first page to an attached preview image" do
    GeneratePdfPreviewJob.perform_now(@blob)

    assert @blob.reload.preview_image.attached?
    assert_equal "image/png", @blob.preview_image.content_type
  end

  test "does nothing when a preview already exists" do
    GeneratePdfPreviewJob.perform_now(@blob)
    existing = @blob.reload.preview_image.blob

    GeneratePdfPreviewJob.perform_now(@blob)

    assert_equal existing, @blob.reload.preview_image.blob
  end

  test "does nothing without a previewer" do
    @blob.stubs(:previewable?).returns(false)

    GeneratePdfPreviewJob.perform_now(@blob)

    assert_not @blob.reload.preview_image.attached?
  end

  test "is enqueued when a pdf is embedded in a post" do
    assert_enqueued_with job: GeneratePdfPreviewJob do
      create_post_embedding(@blob)
    end
  end

  test "is not enqueued for an image" do
    image = create_image_blob

    assert_no_enqueued_jobs only: GeneratePdfPreviewJob do
      create_post_embedding(image)
    end
  end

  private

    def create_post_embedding(blob)
      blogs(:joel).posts.create!(title: "Attached", content: attachment_node_for(blob), status: :published)
    end
end
