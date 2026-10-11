import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  click(event) {
    const chord = event.metaKey || event.ctrlKey
    if (!chord && (event.target.isContentEditable || event.target.closest("input, textarea, select"))) return

    event.preventDefault()
    this.element.click()
  }
}
