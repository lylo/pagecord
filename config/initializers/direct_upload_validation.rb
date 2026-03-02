Rails.configuration.to_prepare do
  ActiveStorage::DirectUploadsController.class_eval do
    before_action :validate_upload, only: :create

    private

      MAX_FILE_SIZES = {
        "image/jpeg" => 10.megabytes,
        "image/jpg" => 10.megabytes,
        "image/png" => 10.megabytes,
        "image/gif" => 10.megabytes,
        "image/webp" => 10.megabytes,
        "video/mp4" => 50.megabytes,
        "video/quicktime" => 50.megabytes,
        "audio/mpeg" => 20.megabytes,
        "audio/wav" => 20.megabytes
      }.freeze

      def validate_upload
        args = params.require(:blob).permit(:content_type, :byte_size)
        max_size = MAX_FILE_SIZES[args[:content_type]]

        head :unprocessable_entity unless max_size && args[:byte_size].to_i <= max_size
      end
  end
end
