# Rewrites an uploaded photo without its GPS and XMP metadata. exiftool edits
# the metadata in place, so the image itself is not re-encoded.
class RemoveImageLocationJob < ApplicationJob
  CONTENT_TYPES = %w[ image/jpeg image/png image/webp ].freeze

  queue_as :low

  discard_on ActiveJob::DeserializationError, ActiveStorage::FileNotFoundError

  def perform(blob)
    blob.open do |file|
      system "exiftool", "-quiet", "-overwrite_original", "-gps:all=", "-xmp:all=", file.path, exception: true

      File.open(file.path) do |stripped|
        unless blob.service.compute_checksum(stripped) == blob.checksum
          blob.upload stripped, identify: false
          blob.save!
        end
      end
    end
  end
end
