import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  initialize() {
    this.autogrow = this.autogrow.bind(this)
    this.debounceTimeout = null
  }

  connect() {
    this.element.style.overflow = "hidden"

    // Run autogrow after a brief delay to ensure content is loaded
    requestAnimationFrame(() => {
      this.autogrow()
    })

    this.element.addEventListener("input", this.queueAutogrow.bind(this))
    this.element.addEventListener("trix-change", this.queueAutogrow.bind(this))
    window.addEventListener("resize", this.queueAutogrow.bind(this))
  }

  disconnect() {
    window.removeEventListener("resize", this.queueAutogrow.bind(this))
    this.element.removeEventListener("trix-change", this.queueAutogrow.bind(this))
  }

  queueAutogrow() {
    clearTimeout(this.debounceTimeout)
    this.debounceTimeout = setTimeout(this.autogrow.bind(this), 100)
  }

  autogrow() {
    this.element.style.height = "auto"
    this.element.style.height = `${this.element.scrollHeight}px`
  }
}
