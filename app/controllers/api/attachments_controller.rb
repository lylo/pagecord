class Api::AttachmentsController < Api::BaseController
  def create
    file = params[:file]

    return render json: { error: "No file provided" }, status: :unprocessable_entity unless file

    max_size = UploadLimits::CONTENT_TYPES[file.content_type]

    return render json: { error: "Unsupported content type: #{file.content_type}" }, status: :unprocessable_entity unless max_size

    if file.size > max_size
      return render json: { error: "File too large (max #{max_size / 1.megabyte}MB for #{file.content_type})" }, status: :unprocessable_entity
    end

    # Blobs are minted here rather than attached to a post, so the validator
    # never sees them. Without this the API is a way round the allowance.
    quota = Current.blog.user.upload_quota

    unless quota.allowed_content_types.include?(file.content_type)
      return render json: { error: quota_error(quota) }, status: :forbidden
    end

    blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: file.original_filename, content_type: file.content_type)

    render_blob blob
  end

  private

    def quota_error(quota)
      if quota.exceeded?
        "You've used all #{UploadQuota::FREE_LIMIT} free uploads. Subscribe to upload more."
      else
        "Video uploads need a paid subscription"
      end
    end

    def render_blob(blob)
      render json: {
        attachable_sgid: blob.attachable_sgid,
        url: url_for(blob)
      }, status: :created
    end
end
