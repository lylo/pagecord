import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    shortcuts: Object
  }

  connect() {
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
  }

  handleKeydown(event) {
    // Don't trigger shortcuts when typing in input fields
    const target = event.target
    if (target.tagName === "INPUT" || target.tagName === "TEXTAREA" || target.isContentEditable) {
      return
    }

    // Don't trigger if any modifier keys are pressed
    if (event.metaKey || event.ctrlKey || event.altKey || event.shiftKey) {
      return
    }

    // Check if pressed key matches any configured shortcut
    const url = this.shortcutsValue[event.key.toLowerCase()]
    if (url) {
      event.preventDefault()
      window.location.href = url
    }
  }
}
