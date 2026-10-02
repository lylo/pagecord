require "test_helper"

class ActiveStorage::Representations::RedirectControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blob = ActiveStorage::Blob.create_and_upload!(io: file_fixture("document.pdf").open, filename: "document.pdf", content_type: "application/pdf")
  end

  test "waits for the job instead of generating a preview" do
    ActiveStorage::Preview.any_instance.expects(:process).never

    get rails_representation_path(@blob.preview(resize_to_limit: [ 1024, 768 ]))

    assert_response :accepted
  end

  test "redirects once the job has attached the preview" do
    GeneratePreviewJob.perform_now(@blob)

    get rails_representation_path(@blob.reload.preview(resize_to_limit: [ 1024, 768 ]))

    assert_response :redirect
  end

  test "still processes an image variant" do
    get rails_representation_path(create_image_blob.variant(resize_to_limit: [ 100, 100 ]))

    assert_response :redirect
  end
end
