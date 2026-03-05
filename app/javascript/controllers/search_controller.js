import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "container", "form"]
  static values = { url: String }

  connect() {
    this.timeout = null
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)

    if (this.hasInputTarget) {
      this.inputTarget.addEventListener("keydown", (e) => {
        if (e.key === "Enter") {
          clearTimeout(this.timeout)
          this.submitSearch()
        }
      })
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
  }

  toggle() {
    if (this.hasContainerTarget && this.containerTarget.classList.contains("hidden")) {
      this.containerTarget.classList.remove("hidden")
      this.inputTarget.focus()
    } else {
      if (this.hasContainerTarget) {
        this.containerTarget.classList.add("hidden")
      }
      if (this.hasInputTarget) {
        this.inputTarget.value = ""
      }
      this.clearSearch()
    }
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const query = this.inputTarget.value.trim()
      if (query.length === 0) {
        this.clearSearch()
      } else if (query.length >= 2) {
        this.submitSearch()
      }
    }, 300)
  }

  submitSearch() {
    if (this.hasFormTarget) {
      this.formTarget.requestSubmit()
    }
  }

  clearSearch() {
    if (this.hasFormTarget) {
      window.location.href = this.formTarget.action
    } else if (this.hasUrlValue) {
      window.location.href = this.urlValue
    }
  }

  handleKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault()
      if (this.hasContainerTarget && this.containerTarget.classList.contains("hidden")) {
        this.toggle()
      } else if (this.hasInputTarget) {
        this.inputTarget.focus()
        this.inputTarget.select()
      }
    }

    if (event.key === "Escape") {
      event.preventDefault()
      if (this.hasInputTarget && this.inputTarget.value) {
        this.inputTarget.value = ""
        this.clearSearch()
      } else if (window.location.search) {
        this.clearSearch()
      } else if (this.hasContainerTarget) {
        this.containerTarget.classList.add("hidden")
      }
    }
  }
}
