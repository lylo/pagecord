import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect () {
    console.log("select controller connected")
  }

  handleChange(event) {
    const path = event.target.selectedOptions[0].dataset.path;
    console.log(path);
    if (path) {
      window.location.href = path;
    }
  }
}