class App::LinkPreviewsController < App::BaseController
  rate_limit to: 10, within: 1.minute, by: -> { Current.user.id }

  def create
    preview = LinkPreview.new(params.expect(:url)).fetch
    blob = preview.create_image_blob(allowed_content_types: Current.user.upload_quota.allowed_content_types)

    render json: {
      title: preview.title,
      description: preview.description,
      image: blob && image_json(blob, preview)
    }
  rescue => e
    Rails.logger.info "Link preview failed for #{params[:url]}: #{e.message}"
    head :unprocessable_entity
  end

  private

    def image_json(blob, preview)
      {
        attachable_sgid: blob.attachable_sgid,
        url: url_for(blob),
        content_type: blob.content_type,
        filename: blob.filename.to_s,
        width: preview.image_width,
        height: preview.image_height
      }
    end
end
