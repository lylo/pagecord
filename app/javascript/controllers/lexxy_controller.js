import { Controller } from "@hotwired/stimulus"

const maxFileSizes = {
  "image/jpeg": 10, "image/jpg": 10, "image/png": 10,
  "image/gif": 10, "image/webp": 10,
  "video/mp4": 50, "video/quicktime": 50,
  "audio/mpeg": 20, "audio/wav": 20,
  "application/pdf": 10
}

const typingAttributes = ["autocapitalize", "autocorrect", "spellcheck"]

export default class extends Controller {
  connect() {
    this.element.addEventListener("lexxy:file-accept", this.#validateFile)
    this.element.addEventListener("lexxy:editor-initialized", this.#syncTypingAttributes)
    this.element.addEventListener("focusin", this.#syncTypingAttributesAfterFocus)
    this.#syncTypingAttributes()
  }

  disconnect() {
    this.element.removeEventListener("lexxy:file-accept", this.#validateFile)
    this.element.removeEventListener("lexxy:editor-initialized", this.#syncTypingAttributes)
    this.element.removeEventListener("focusin", this.#syncTypingAttributesAfterFocus)
  }

  #validateFile = (e) => {
    const { type, size } = e.detail.file

    if (this.element.dataset.attachments !== "true") {
      e.preventDefault()
      alert("You've used all your free uploads. Subscribe to upload more.")
      return
    }

    if (this.element.dataset.videos !== "true" && type.startsWith("video/")) {
      e.preventDefault()
      alert("Video uploads need a paid subscription.")
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
      alert(`This file is too large. ${this.#categoryFor(type)} are limited to ${limitMB}MB.`)
    }
  }

  // PDF is the only application/* type in maxFileSizes, so the media type is
  // enough to name the category back to the writer.
  #categoryFor(type) {
    switch (type.split("/")[0]) {
      case "video": return "Videos"
      case "audio": return "Audio files"
      case "application": return "PDFs"
      default: return "Images"
    }
  }

  #syncTypingAttributes = () => {
    const editorContent = this.element.editorContentElement || this.element.querySelector(".lexxy-editor__content")
    if (!editorContent) return

    for (const attribute of typingAttributes) {
      if (this.element.hasAttribute(attribute)) {
        editorContent.setAttribute(attribute, this.element.getAttribute(attribute))
      }
    }
  }

  #syncTypingAttributesAfterFocus = () => {
    this.#syncTypingAttributes()
    requestAnimationFrame(this.#syncTypingAttributes)
  }
}
