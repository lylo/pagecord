import { Controller } from "@hotwired/stimulus"

const maxFileSizes = {
  "image/jpeg": 10, "image/jpg": 10, "image/png": 10,
  "image/gif": 10, "image/webp": 10,
  "video/mp4": 50, "video/quicktime": 50,
  "audio/mpeg": 20, "audio/wav": 20
}

const typingAttributes = ["autocapitalize", "autocorrect", "spellcheck"]

export default class extends Controller {
  connect() {
    this.element.addEventListener("lexxy:file-accept", this.#validateFile)
    this.element.addEventListener("lexxy:editor-initialized", this.#syncTypingAttributes)
    this.element.addEventListener("focusin", this.#syncTypingAttributesAfterFocus)
    this.#installClipboardPasteOverride()
    this.#syncTypingAttributes()
  }

  disconnect() {
    this.element.removeEventListener("lexxy:file-accept", this.#validateFile)
    this.element.removeEventListener("lexxy:editor-initialized", this.#syncTypingAttributes)
    this.element.removeEventListener("focusin", this.#syncTypingAttributesAfterFocus)
    this.#restoreClipboardPaste()
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

  #installClipboardPasteOverride() {
    if (!this.element.clipboard?.paste || this.originalClipboardPaste) return

    this.originalClipboardPaste = this.element.clipboard.paste.bind(this.element.clipboard)
    this.element.clipboard.paste = this.#pastePreferringImageFiles
  }

  #restoreClipboardPaste() {
    if (!this.originalClipboardPaste || !this.element.clipboard) return

    this.element.clipboard.paste = this.originalClipboardPaste
    this.originalClipboardPaste = null
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

  #pastePreferringImageFiles = (event) => {
    const imageFiles = this.#pastedImageFilesFrom(event)

    if (imageFiles.length === 0) {
      return this.originalClipboardPaste?.(event)
    }

    event.preventDefault()
    this.#insertUploadNodes(imageFiles)
    return true
  }

  #insertUploadNodes(files) {
    this.#preservingScrollPosition(() => {
      this.element.focus()
      this.element.contents.uploadFiles(files)
    })
  }

  // Mirrors Lexxy's internal Safari scroll-jump fix for pasted attachments
  async #preservingScrollPosition(callback) {
    const { scrollX, scrollY } = window
    callback()
    await new Promise(resolve => requestAnimationFrame(resolve))
    window.scrollTo(scrollX, scrollY)
  }

  #pastedImageFilesFrom(event) {
    if (this.element.dataset.attachments !== "true") return []

    const files = Array.from(event.clipboardData?.files || [])
    const imageFiles = files.filter(file => file.type.startsWith("image/"))
    if (imageFiles.length === 0) return []

    return imageFiles
  }
}
