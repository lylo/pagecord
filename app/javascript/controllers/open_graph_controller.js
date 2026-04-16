import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "uploadArea"]

  open(event) {
    event.preventDefault()
    this.inputTarget.click()
  }

  handleFileSelect(event) {
    const file = event.target.files[0]
    if (!file) return

    const allowedTypes = ["image/jpeg", "image/png", "image/webp"]
    if (!allowedTypes.includes(file.type)) {
      alert("Please select a JPEG, PNG, or WebP image.")
      return
    }

    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewTarget.src = e.target.result
      this.previewTarget.classList.remove("hidden")
      if (this.hasUploadAreaTarget) this.uploadAreaTarget.classList.add("hidden")
    }
    reader.readAsDataURL(file)
  }
}
