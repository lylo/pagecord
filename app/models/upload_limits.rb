class UploadLimits
  CONTENT_TYPES = {
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
end
