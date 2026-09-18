import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "element"]

  connect() {
    this.hide()
  }

  toggle(event) {
    event.preventDefault()
    this.elementTarget.classList.toggle("hidden")
  }

  hide(event) {
    if (event?.type === "click" && this.buttonTarget.contains(event.target)) return

    this.elementTarget.classList.add("hidden")
  }
}
