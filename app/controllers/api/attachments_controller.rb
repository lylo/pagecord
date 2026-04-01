class Api::AttachmentsController < Api::BaseController
  def create
    file = params[:file]

    return render json: { error: "No file provided" }, status: :unprocessable_entity unless file

    max_size = UploadLimits::CONTENT_TYPES[file.content_type]

    unless max_size
      return render json: { error: "Unsupported content type: #{file.content_type}" }, status: :unprocessable_entity
    end

    if file.size > max_size
      return render json: { error: "File too large (max #{max_size / 1.megabyte}MB for #{file.content_type})" }, status: :unprocessable_entity
    end

    blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: file.original_filename, content_type: file.content_type)

    render json: {
      attachable_sgid: blob.attachable_sgid,
      url: url_for(blob)
    }, status: :created
  end
end
