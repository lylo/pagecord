import { Controller } from "@hotwired/stimulus"

const maxFileSizes = {
  "image/jpeg": 10, "image/jpg": 10, "image/png": 10,
  "image/gif": 10, "image/webp": 10,
  "video/mp4": 50, "video/quicktime": 50,
  "audio/mpeg": 20, "audio/wav": 20
}

export default class extends Controller {
  connect() {
    this.element.addEventListener("lexxy:file-accept", this.#validateFile)
  }

  disconnect() {
    this.element.removeEventListener("lexxy:file-accept", this.#validateFile)
  }

  #validateFile = (e) => {
    const { type, size } = e.detail.file

    if (this.element.dataset.attachments !== "true") {
      e.preventDefault()
      alert("Attachments are only available for paying customers")
      return
    }

    const supportedType = type in maxFileSizes

    if (!supportedType) {
      e.preventDefault()
      alert("Unsupported attachment type, sorry!")
      return
    }

    const limitMB = maxFileSizes[type]

    if (size > limitMB * 1024 * 1024) {
      e.preventDefault()
      const category = type.startsWith("video/") ? "Videos" : type.startsWith("audio/") ? "Audio files" : "Images"
      alert(`This file is too large. ${category} are limited to ${limitMB}MB.`)
    }
  }
}
