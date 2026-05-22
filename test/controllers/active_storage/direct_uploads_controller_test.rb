require "test_helper"

class ActiveStorage::DirectUploadsControllerTest < ActionDispatch::IntegrationTest
  test "allows image upload within size limit" do
    post rails_direct_uploads_path, params: {
      blob: { filename: "photo.jpg", content_type: "image/jpeg", byte_size: 5.megabytes, checksum: "abc123" }
    }, as: :json

    assert_response :success
  end

  test "allows video upload within size limit" do
    post rails_direct_uploads_path, params: {
      blob: { filename: "clip.mp4", content_type: "video/mp4", byte_size: 40.megabytes, checksum: "abc123" }
    }, as: :json

    assert_response :success
  end

  test "rejects image over 10MB" do
    post rails_direct_uploads_path, params: {
      blob: { filename: "huge.png", content_type: "image/png", byte_size: 11.megabytes, checksum: "abc123" }
    }, as: :json

    assert_response :unprocessable_entity
  end

  test "rejects video over 50MB" do
    post rails_direct_uploads_path, params: {
      blob: { filename: "huge.mp4", content_type: "video/mp4", byte_size: 51.megabytes, checksum: "abc123" }
    }, as: :json

    assert_response :unprocessable_entity
  end

  test "rejects disallowed content type" do
    post rails_direct_uploads_path, params: {
      blob: { filename: "script.exe", content_type: "application/octet-stream", byte_size: 1.megabyte, checksum: "abc123" }
    }, as: :json

    assert_response :unprocessable_entity
  end
end
