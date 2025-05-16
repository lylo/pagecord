import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.querySelectorAll('a').forEach(link => {
      link.dataset.turboFrame = "_top"
    })
  }
}