import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "container", "form"]

  connect() {
    this.timeout = null

    // Handle Cmd+F (Mac) or Ctrl+F (Windows/Linux) to focus search
    document.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  toggle() {
    if (this.containerTarget.classList.contains("hidden")) {
      this.containerTarget.classList.remove("hidden")
      this.inputTarget.focus()
    } else {
      this.containerTarget.classList.add("hidden")
      this.inputTarget.value = ""
      this.formTarget.requestSubmit()
    }
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 300) // Debounce by 300ms
  }

  handleKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === "f") {
      event.preventDefault()
      if (this.containerTarget.classList.contains("hidden")) {
        this.toggle()
      } else {
        this.inputTarget.focus()
        this.inputTarget.select()
      }
    }

    if (event.key === "Escape") {
      event.preventDefault()
      if (this.inputTarget.value) {
        // Clear the search if there's text
        this.inputTarget.value = ""
        this.formTarget.requestSubmit()
      } else {
        // Hide search container if it's empty
        this.containerTarget.classList.add("hidden")
      }
    }
  }
}
