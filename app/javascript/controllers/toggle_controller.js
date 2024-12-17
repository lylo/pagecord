import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["element"]

  connect() {
    this.hide()
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    this.elementTarget.classList.toggle("hidden")
  }

  hide() {
    if (!this.elementTarget.classList.contains("hidden")) {
      this.elementTarget.classList.add("hidden")
    }
  }
}
