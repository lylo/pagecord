import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  handleChange(event) {
    const path = event.target.selectedOptions[0].dataset.path;
    if (path) {
      window.location.href = path;
    }
  }
}