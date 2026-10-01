require "test_helper"

class App::PreviewsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    login_as users(:joel)
    @blob = ActiveStorage::Blob.create_and_upload!(io: file_fixture("document.pdf").open, filename: "document.pdf", content_type: "application/pdf")
  end

  test "accepts while the preview is being generated" do
    get app_preview_path(@blob.signed_id)

    assert_response :accepted
  end

  test "redirects to the preview once it is ready" do
    @blob.preview_image.attach(io: file_fixture("space.jpg").open, filename: "preview.jpg", content_type: "image/jpeg")

    get app_preview_path(@blob.signed_id)

    assert_redirected_to rails_blob_path(@blob.preview_image)
  end
end
