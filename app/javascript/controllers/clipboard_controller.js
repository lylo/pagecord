import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.textContent)

    this.buttonTarget.textContent = "Copied!"
    setTimeout(() => this.buttonTarget.textContent = "Copy", 2000)
  }
}
