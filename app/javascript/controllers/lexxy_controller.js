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
          "audio/mpeg": 20, "audio/wav": 20
        }

        editor.addEventListener("lexxy:file-accept", (e) => {
          const { type, size } = e.detail.file
          const maxMB = maxFileSizes[type]

          if (!maxMB) {
            e.preventDefault()
            alert("Unsupported attachment type, sorry!")
          } else if (size > maxMB * 1024 * 1024) {
            e.preventDefault()
            alert(`This file is too large. ${type.startsWith("video/") ? "Videos" : "Images"} are limited to ${maxMB}MB.`)
          }
        })
      }
    })
  }
}
