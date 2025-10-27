class GenerateOpenGraphImageJob < ApplicationJob
  queue_as :default

  def perform(imageable_type, imageable_id)
    imageable = imageable_type.constantize.find_by(id: imageable_id)
    return unless imageable
    return unless imageable.should_generate_og_image?

    preview = SocialPreview.new(imageable)
    og_image = imageable.open_graph_image || imageable.create_open_graph_image!
    og_image.image.purge if og_image.image.attached?

    og_image.image.attach(
      io: StringIO.new(preview.to_png),
      filename: imageable.og_image_filename,
      content_type: "image/png"
    )

    Rails.logger.info("Generated social preview for #{imageable_type} #{imageable.id}")
  rescue => e
    Rails.logger.error("Failed to generate OG image for #{imageable_type} #{imageable_id}: #{e.message}")
    raise
  end
end
