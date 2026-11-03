import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button", "status"]
  static classes = ["copied"]
  static values = { text: String }

  connect() {
    this.label = this.buttonTarget.textContent
  }

  copy() {
    navigator.clipboard.writeText(this.hasTextValue ? this.textValue : this.sourceTarget.textContent)

    if (this.hasCopiedClass) {
      this.buttonTarget.classList.add(this.copiedClass)
      this.statusTarget.textContent = "Copied"
      clearTimeout(this.timeout)
      this.timeout = setTimeout(() => {
        this.buttonTarget.classList.remove(this.copiedClass)
        this.statusTarget.textContent = ""
      }, 2000)
    } else {
      this.buttonTarget.textContent = "Copied!"
      setTimeout(() => this.buttonTarget.textContent = this.label, 2000)
    }
  }
}
