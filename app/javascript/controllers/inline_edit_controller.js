import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "input"]

  edit() {
    this.toggle(true)
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  cancel() {
    this.inputTarget.value = this.inputTarget.defaultValue
    this.toggle(false)
  }

  toggle(editing) {
    this.displayTargets.forEach((target) => target.classList.toggle("hidden", editing))
    this.formTarget.classList.toggle("hidden", !editing)
  }
}
