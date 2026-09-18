import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.keydown = this.keydown.bind(this)
    // Capture, so the settings drawer's Escape handler hasn't closed it yet
    document.addEventListener("keydown", this.keydown, true)
  }

  disconnect() {
    document.removeEventListener("keydown", this.keydown, true)
    document.documentElement.removeAttribute("data-writing-mode")
  }

  toggle() {
    document.documentElement.toggleAttribute("data-writing-mode")
  }

  keydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.shiftKey && event.key.toLowerCase() === "f") {
      event.preventDefault()
      this.toggle()
    } else if (event.key === "Escape" && !this.element.querySelector("[data-open]")) {
      document.documentElement.removeAttribute("data-writing-mode")
    }
  }
}
