import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.querySelectorAll('a').forEach(link => {
      // Only links that haven't chosen a frame. A link targeting its own frame
      // (the comments loader) means it deliberately, so don't override it.
      if (!link.dataset.turboFrame) {
        link.dataset.turboFrame = "_top"
      }
    })
  }
}