import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.timeout = null

    // Handle Cmd+F (Mac) or Ctrl+F (Windows/Linux) to focus search
    document.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  handleKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === "f") {
      event.preventDefault()
      this.inputTarget.focus()
      this.inputTarget.select()
    }

    if (event.key === "Escape") {
      event.preventDefault()
      if (this.inputTarget.value) {
        // Clear the search if there's text
        this.inputTarget.value = ""
        this.element.closest("form").requestSubmit()
      } else {
        // Blur the input if it's already empty
        this.inputTarget.blur()
      }
    }
  }

  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.closest("form").requestSubmit()
    }, 300) // Debounce by 300ms
  }
}
