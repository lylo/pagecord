import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]
  static values = { text: String }

  connect() {
    this.label = this.buttonTarget.textContent
  }

  copy() {
    navigator.clipboard.writeText(this.hasTextValue ? this.textValue : this.sourceTarget.textContent)

    this.buttonTarget.textContent = "Copied!"
    setTimeout(() => this.buttonTarget.textContent = this.label, 2000)
  }
}
