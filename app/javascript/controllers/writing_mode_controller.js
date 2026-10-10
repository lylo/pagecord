import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  disconnect() {
    document.documentElement.removeAttribute("data-writing-mode")
  }

  toggle() {
    document.documentElement.toggleAttribute("data-writing-mode")
  }

  // Bound in the capture phase, so Escape arrives before the settings drawer closes and before the editor blurs
  exit(event) {
    if (!this.writing || this.element.querySelector("[data-open]")) return

    event.stopPropagation()
    this.toggle()
  }

  leaveText(event) {
    if (!event.defaultPrevented && this.element.contains(document.activeElement)) document.activeElement.blur()
  }

  get writing() {
    return document.documentElement.hasAttribute("data-writing-mode")
  }
}
