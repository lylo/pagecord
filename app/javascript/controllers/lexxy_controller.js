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
        const maxFileSizes = {
          "image/jpeg": 10, "image/jpg": 10, "image/png": 10,
          "image/gif": 10, "image/webp": 10,
          "video/mp4": 50, "video/quicktime": 50,
          "audio/mpeg": 20, "audio/wav": 20,
          "application/pdf": 20
        }

        editor.addEventListener("lexxy:file-accept", (e) => {
          const { type, size } = e.detail.file
          const supportedType = type in maxFileSizes

          if (!supportedType) {
            e.preventDefault()
            alert("Unsupported attachment type, sorry!")
            return
          }

          const limitMB = maxFileSizes[type]

          if (size > limitMB * 1024 * 1024) {
            e.preventDefault()
            const category = type.startsWith("video/") ? "Videos" : type.startsWith("audio/") ? "Audio files" : type === "application/pdf" ? "PDFs" : "Images"
            alert(`This file is too large. ${category} are limited to ${limitMB}MB.`)
          }
        })
      }
    })
  }
}
