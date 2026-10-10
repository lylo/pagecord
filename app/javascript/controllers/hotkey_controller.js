import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  click(event) {
    if (event.target.closest("input, textarea, select, [contenteditable]")) return

    event.preventDefault()
    this.element.click()
  }
}
