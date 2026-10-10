import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.keydown = this.keydown.bind(this)
    // Capture, so Escape arrives before the settings drawer closes and before the editor blurs
    document.addEventListener("keydown", this.keydown, true)
    this.leaveText = this.leaveText.bind(this)
    document.addEventListener("keydown", this.leaveText)
  }

  disconnect() {
    document.removeEventListener("keydown", this.keydown, true)
    document.removeEventListener("keydown", this.leaveText)
    document.documentElement.removeAttribute("data-writing-mode")
  }

  toggle() {
    document.documentElement.toggleAttribute("data-writing-mode")
  }

  keydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.shiftKey && event.key.toLowerCase() === "f") {
      event.preventDefault()
      this.toggle()
    } else if (event.key === "Escape" && this.writing && !this.element.querySelector("[data-open]")) {
      event.stopPropagation()
      this.toggle()
    }
  }

  leaveText(event) {
    if (event.key === "Escape" && !event.defaultPrevented && this.element.contains(document.activeElement)) {
      document.activeElement.blur()
    }
  }

  get writing() {
    return document.documentElement.hasAttribute("data-writing-mode")
  }
}
