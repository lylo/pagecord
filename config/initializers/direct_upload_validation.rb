module DirectUploadValidation
  extend ActiveSupport::Concern

  included do
    before_action :validate_upload, only: :create
  end

  private

    def validate_upload
      args = params.require(:blob).permit(:content_type, :byte_size)
      max_size = UploadLimits::CONTENT_TYPES[args[:content_type]]

      head :unprocessable_entity unless max_size && args[:byte_size].to_i <= max_size
    end
end

Rails.autoloaders.main.on_load("ActiveStorage::DirectUploadsController") do |klass, _abspath|
  klass.include DirectUploadValidation unless klass < DirectUploadValidation
end
