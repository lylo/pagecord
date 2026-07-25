module DirectUploadValidation
  extend ActiveSupport::Concern

  included do
    include Authentication

    rate_limit to: 60, within: 1.minute, by: -> { Current.user&.id || request.ip }
    before_action :validate_upload, only: :create
  end

  private

    def validate_upload
      args = params.require(:blob).permit(:filename, :content_type, :byte_size, :checksum)
      max_size = UploadLimits::CONTENT_TYPES[args[:content_type]]

      return head :unprocessable_entity unless max_size && args[:byte_size].to_i <= max_size

      return head :forbidden unless Current.user

      # Advisory only – blobs are minted before they're attached, so this is racy
      # across tabs. The authoritative gate is UploadQuota::Validator on Post.
      head :forbidden unless Current.user.upload_quota.allowed_content_types.include?(args[:content_type])
    end
end

Rails.autoloaders.main.on_load("ActiveStorage::DirectUploadsController") do |klass, _abspath|
  klass.include DirectUploadValidation unless klass < DirectUploadValidation
end
