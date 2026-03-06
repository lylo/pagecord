require "test_helper"

class Api::AttachmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "api.example.com"

    @blog = blogs(:joel)
    @user = users(:joel)
    @user.update!(trial_ends_at: 30.days.from_now)

    @api_key = SecureRandom.hex(20)
    @blog.update!(api_key_digest: Digest::SHA256.hexdigest(@api_key), features: [ "api" ])
  end

  test "upload returns 201 with attachable_sgid and url" do
    file = fixture_file_upload("space.jpg", "image/jpeg")

    post "/attachments", params: { file: file }, headers: auth_header

    assert_response :created
    json = JSON.parse(response.body)
    assert json["attachable_sgid"].present?
    assert json["url"].present?
  end

  test "upload creates a blob" do
    file = fixture_file_upload("space.jpg", "image/jpeg")

    assert_difference -> { ActiveStorage::Blob.count } do
      post "/attachments", params: { file: file }, headers: auth_header
    end
  end

  test "rejects unsupported content type" do
    file = fixture_file_upload("space.jpg", "text/plain")

    post "/attachments", params: { file: file }, headers: auth_header

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_match "Unsupported content type", json["error"]
  end

  test "rejects file exceeding size limit" do
    file = fixture_file_upload("space.jpg", "image/jpeg")
    ActionDispatch::Http::UploadedFile.any_instance.stubs(:size).returns(11.megabytes)

    post "/attachments", params: { file: file }, headers: auth_header

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_match "File too large", json["error"]
  end

  test "returns 422 without file param" do
    post "/attachments", headers: auth_header

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "No file provided", json["error"]
  end

  test "returns unauthorized without token" do
    post "/attachments"
    assert_response :unauthorized
  end

  test "returns forbidden without premium access" do
    @user.subscription.destroy!
    @user.update!(trial_ends_at: nil)

    file = fixture_file_upload("space.jpg", "image/jpeg")
    post "/attachments", params: { file: file }, headers: auth_header

    assert_response :forbidden
  end

  private

    def auth_header(token = @api_key)
      { "Authorization" => "Bearer #{token}" }
    end
end
