import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.querySelectorAll('input[type="radio"]').forEach(radio => {
      radio.addEventListener('change', () => this.element.requestSubmit())
    })
  }
}