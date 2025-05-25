import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Initialize and enhance the Trix editor
    this.element.addEventListener("trix-initialize", (event) => {
      const editor = event.target
      const subscribed = editor.dataset.subscribed === "true"

      if (!subscribed) {
        editor.addEventListener("trix-file-accept", (e) => {
          e.preventDefault()
          alert("Attachments are only available for paying customers")
        })

        editor.addEventListener("trix-attachment-add", (e) => {
          e.attachment.remove()
          alert("Attachments are only available for paying customers")
        })
      } else {
        editor.addEventListener("trix-file-accept", (e) => {
          const exceedsMaxFileSize = e.file.size > (1024 * 1024 * 20) // 20MB
          const acceptedFileType = [
            "image/jpeg", "image/jpg", "image/png",
            "image/gif", "image/webp", "video/mp4",
            "video/quicktime",
          ].includes(e.file.type)

          if (exceedsMaxFileSize || !acceptedFileType) {
            e.preventDefault()
            if (exceedsMaxFileSize) {
              alert("Attachments are limited to 20MB in size right now, sorry.")
            } else {
              alert("Unsupported attachment type, sorry!")
            }
          }
        })

        editor.addEventListener("trix-attachment-add", (e) => {
          const attachment = e.attachment
          if (attachment.file && attachment.file.type.startsWith("video/")) {
            const thumbnailUrl = "/video.png"
            attachment.setAttributes({
              url: thumbnailUrl,
              contentType: "image/png",
              filename: "video-thumbnail.png",
              previewable: true,
            })
          }
        })
      }
    })
  }
}
