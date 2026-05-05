import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "editor"]

  toggle() {
    this.editorTarget.classList.toggle("hidden", !this.checkboxTarget.checked)
  }
}
