import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.querySelectorAll('input[type="checkbox"]').forEach(cb => {
      cb.addEventListener('change', () => this.element.requestSubmit())
    })
  }
}
