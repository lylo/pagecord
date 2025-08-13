import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "container", "form"]

  connect() {
    this.timeout = null
    // Handle Cmd+K (Mac) or Ctrl+K (Windows/Linux) to focus search
    document.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  toggle() {
    if (this.hasContainerTarget && this.containerTarget.classList.contains("hidden")) {
      this.containerTarget.classList.remove("hidden")
      this.inputTarget.focus()
    } else {
      if (this.hasContainerTarget) {
        this.containerTarget.classList.add("hidden")
      }
      this.inputTarget.value = ""
      this.clearSearch()
    }
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      if (this.inputTarget.value.trim() === "") {
        this.clearSearch()
      } else {
        this.formTarget.requestSubmit()
      }
    }, 300)
  }

  clearSearch() {
    window.location.href = this.formTarget.action
  }

  handleKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault()
      if (this.hasContainerTarget && this.containerTarget.classList.contains("hidden")) {
        this.toggle()
      } else {
        this.inputTarget.focus()
        this.inputTarget.select()
      }
    }

    if (event.key === "Escape") {
      event.preventDefault()
      if (this.inputTarget.value) {
        this.inputTarget.value = ""
        this.clearSearch()
      } else if (this.hasContainerTarget) {
        this.containerTarget.classList.add("hidden")
      }
    }
  }
}
