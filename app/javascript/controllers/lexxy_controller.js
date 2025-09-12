import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("lexxy:initialize", (event) => {
      const editor = event.target
      const attachments = editor.dataset.attachments === "true"

      if (!attachments) {
        editor.addEventListener("lexxy:file-accept", (e) => {
          e.preventDefault()
          alert("Attachments are only available for paying customers")
        })
      } else {
        editor.addEventListener("lexxy:file-accept", (e) => {
          const exceedsMaxFileSize = e.detail.file.size > (1024 * 1024 * 20) // 20MB
          const acceptedFileType = [
            "image/jpeg", "image/jpg", "image/png",
            "image/gif", "image/webp", "video/mp4",
            "video/quicktime",
          ].includes(e.detail.file.type)

          if (exceedsMaxFileSize || !acceptedFileType) {
            e.preventDefault()
            if (exceedsMaxFileSize) {
              alert("Attachments are limited to 20MB in size right now, sorry.")
            } else {
              alert("Unsupported attachment type, sorry!")
            }
          }
        })
      }
    })
  }
}
