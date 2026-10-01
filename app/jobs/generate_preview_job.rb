# Renders a PDF's first page or a video's first frame once, so views can treat
# it as an ordinary image and let Cloudflare resize it. Passing no
# transformations means ActiveStorage::Preview#processed attaches preview_image
# and skips the variant, which is all we want: a second derivative would be
# dead weight.
#
# Silently does nothing without pdftoppm or ffmpeg on the box: previewable? is
# false, and the attachment renders as it does today.
class GeneratePreviewJob < ApplicationJob
  queue_as :low

  # PreviewError means the file itself is unreadable – a missing binary is
  # already caught by the previewable? guard – so retrying can never succeed.
  discard_on ActiveJob::DeserializationError, ActiveStorage::PreviewError

  # A direct upload creates the blob before the browser sends the file. If it
  # never arrives, the upload was abandoned and there is nothing to preview.
  retry_on ActiveStorage::FileNotFoundError, wait: :polynomially_longer, attempts: 8 do
  end

  def perform(blob)
    return if blob.preview_image.attached? || !blob.previewable?

    blob.preview({}).processed
  end
end
