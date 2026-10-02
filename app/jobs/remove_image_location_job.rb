# Rewrites an uploaded photo without its GPS coordinates. exiftool edits the
# metadata only, so the image itself is not re-encoded.
class RemoveImageLocationJob < ApplicationJob
  class UnwritableImage < StandardError; end

  CONTENT_TYPES = %w[ image/jpeg image/png image/webp ].freeze

  queue_as :low

  discard_on ActiveJob::DeserializationError, ActiveStorage::FileNotFoundError
  discard_on(UnwritableImage) { |_job, error| Sentry.capture_exception(error) if Sentry.initialized? }

  def perform(blob)
    return unless blob.content_type.in?(CONTENT_TYPES)

    # Piped rather than passed a path, so exiftool goes by the bytes and not a filename that may not match them
    stripped, error, status = Open3.capture3("exiftool", "-quiet", "-gps:all=", "-xmp:gps*=", "-o", "-", "-", stdin_data: blob.download, binmode: true)
    raise UnwritableImage, "Blob #{blob.id}: #{error.strip}" unless status.success?

    io = StringIO.new(stripped)
    unless blob.service.compute_checksum(io) == blob.checksum
      blob.upload io, identify: false
      blob.save!
    end
  end
end
