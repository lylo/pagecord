import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "button", "eye", "eyeSlash"]

  toggle() {
    const masked = this.fieldTarget.type === "password"

    this.fieldTarget.type = masked ? "text" : "password"
    this.buttonTarget.setAttribute("aria-label", masked ? "Hide password" : "Show password")
    this.eyeTarget.classList.toggle("hidden", masked)
    this.eyeSlashTarget.classList.toggle("hidden", !masked)
  }
}
