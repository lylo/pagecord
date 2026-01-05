import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { message: { type: String, default: "✅ Saved!" } }
  static targets = ["button"]

  showMessage(event) {
    if (!event.detail.success) return

    const originalText = this.buttonTarget.value
    this.buttonTarget.value = this.messageValue
    this.buttonTarget.disabled = true

    setTimeout(() => {
      this.buttonTarget.value = originalText
      this.buttonTarget.disabled = false
    }, 2000)
  }
}
