# Lexxy polls this after an upload: 2xx while the preview is being generated,
# anything else once it's ready.
class App::PreviewsController < App::BaseController
  def show
    blob = ActiveStorage::Blob.find_signed!(params[:id])

    if blob.preview_image.attached?
      redirect_to rails_blob_path(blob.preview_image)
    else
      head :accepted
    end
  end
end
