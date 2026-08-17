# Renders a PDF's first page once, so the blog page can treat it as an ordinary
# image and let Cloudflare resize it. Passing no transformations means
# ActiveStorage::Preview#processed attaches preview_image and skips the variant,
# which is all we want: a second derivative would be dead weight.
#
# The output is a 72dpi PNG, which Rails' PopplerPDFPreviewer hardcodes.
#
# Silently does nothing without poppler (pdftoppm) on the box: previewable? is
# false, and the attachment falls back to a file chip.
class GeneratePdfPreviewJob < ApplicationJob
  queue_as :low

  # PreviewError means the file itself is unreadable – a missing pdftoppm is
  # already caught by the previewable? guard – so retrying can never succeed.
  discard_on ActiveJob::DeserializationError, ActiveStorage::PreviewError

  def perform(blob)
    return if blob.preview_image.attached? || !blob.previewable?

    blob.preview({}).processed
  end
end
