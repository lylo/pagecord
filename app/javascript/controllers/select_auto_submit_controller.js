import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.querySelectorAll('select').forEach(select => {
      select.addEventListener('change', () => this.element.requestSubmit())
    })
  }
}