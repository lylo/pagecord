import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "output"]

  sign() {
    this.outputTarget.textContent = this.sourceTarget.value
  }
}
