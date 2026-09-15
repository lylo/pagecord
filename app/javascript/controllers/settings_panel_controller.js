import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "tags"]

  connect() {
    this.keydown = this.keydown.bind(this)
    document.addEventListener("keydown", this.keydown)

    if (this.panelTarget.querySelector(".field-error:not(:empty)")) this.open()
  }

  disconnect() {
    document.removeEventListener("keydown", this.keydown)
  }

  open() {
    this.panelTarget.setAttribute("data-open", "")

    // Focus the first field once the drawer is on screen - it's still
    // visibility:hidden on the first frame, so focus wouldn't take
    requestAnimationFrame(() => requestAnimationFrame(() => this.firstField?.focus()))
  }

  close() {
    this.panelTarget.removeAttribute("data-open")
  }

  toggle() {
    this.panelTarget.hasAttribute("data-open") ? this.close() : this.open()
  }

  get firstField() {
    return this.panelTarget.querySelector("input:not([type=hidden]), textarea, select, [contenteditable]:not([contenteditable=false])")
  }

  refreshTags(event) {
    const tags = event.target.value.split(",").map(tag => tag.trim()).filter(Boolean)
    const labels = tags.slice(0, 3).map(tag => `#${tag}`)
    if (tags.length > 3) labels.push(`+${tags.length - 3} more`)
    this.tagsTarget.replaceChildren(...labels.map(text => Object.assign(document.createElement("span"), { textContent: text })))
  }

  keydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === ".") {
      event.preventDefault()
      this.toggle()
    } else if (event.key === "Escape") {
      this.close()
    }
  }
}
