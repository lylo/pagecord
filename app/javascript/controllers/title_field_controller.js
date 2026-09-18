import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  next(event) {
    event.preventDefault()
    this.element.form.querySelector("lexxy-editor")?.focus()
  }
}
