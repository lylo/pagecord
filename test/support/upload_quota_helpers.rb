module UploadQuotaHelpers
  # Builds a post whose content embeds `count` freshly uploaded images, so the
  # user's image quota counts them exactly as a real save would.
  def fill_upload_quota(user, count)
    user.blog.posts.create!(title: "Gallery", content: image_attachment_html(count), status: :published)
  end

  def image_attachment_html(count)
    Array.new(count) { attachment_node_for(create_image_blob) }.join
  end

  def create_image_blob
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/space.jpg")),
      filename: "space.jpg",
      content_type: "image/jpeg"
    )
  end

  def attachment_node_for(blob)
    %(<action-text-attachment sgid="#{blob.attachable_sgid}" content-type="#{blob.content_type}" filename="#{blob.filename}"></action-text-attachment>)
  end
end

ActiveSupport::TestCase.include UploadQuotaHelpers
