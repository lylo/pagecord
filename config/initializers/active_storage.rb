# The presence validator on an attachment's record calls RichText#blank?, which
# renders the whole body for every attachment saved. A nil check doesn't.
ActiveSupport.on_load(:active_storage_attachment) do
  validator = _validators[:record].find { |v| v.is_a?(ActiveRecord::Validations::PresenceValidator) }

  if validator
    _validators[:record].delete(validator)
    skip_callback(:validate, validator)
    validate { errors.add(:record, :blank) if record.nil? }
  end
end

# A representation request answers 202 until GeneratePreviewJob has made the preview.
Rails.autoloaders.main.on_load("ActiveStorage::Representations::BaseController") do |klass, _abspath|
  klass.prepend PendingPreviewRepresentation unless klass < PendingPreviewRepresentation
end

# Hooked on the blob so the editor's preview is ready before the post is saved.
# App::PreviewsController reports when it is.
ActiveSupport.on_load(:active_storage_blob) do
  after_create_commit -> { GeneratePreviewJob.perform_later(self) }, if: :previewable?
end

ActiveSupport.on_load(:active_storage_attachment) do
  after_upload -> { RemoveImageLocationJob.perform_later(blob) if blob.attachments.minimum(:id) == id }
end

Rails.application.config.after_initialize do
  Rails.application.config.active_storage.analyzers.prepend AudioWaveformAnalyzer
end

# Uploads are limited to UploadLimits::CONTENT_TYPES, none of which need the
# loaders libvips marks as untrusted (ImageMagick, SVG, PDF, RAW and others)
require "vips"
Vips.block_untrusted(true)
