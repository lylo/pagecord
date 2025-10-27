class GenerateOpenGraphImageJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post
    return if post.first_image.present?

    preview = SocialPreview.new(post)
    og_image = post.open_graph_image || post.create_open_graph_image!
    og_image.image.purge if og_image.image.attached?

    # Attach new PNG image generated frm the SVG preview
    og_image.image.attach(
      io: StringIO.new(preview.to_png),
      filename: "og-preview-#{post.token}.png",
      content_type: "image/png"
    )

    Rails.logger.info("Generated social preview for post #{post.id}")
  rescue => e
    Rails.logger.error("Failed to generate OG image for post #{post_id}: #{e.message}")
    raise
  end
end
