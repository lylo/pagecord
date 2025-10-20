import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["primary", "dependent"]

  connect() {
    this.toggleDependents()
  }

  toggleDependents() {
    const enabled = this.primaryTarget.checked

    this.dependentTargets.forEach(element => {
      if (element.tagName === "INPUT") {
        element.disabled = !enabled
      } else {
        // For containers
        if (enabled) {
          element.classList.remove("opacity-50", "pointer-events-none")
        } else {
          element.classList.add("opacity-50", "pointer-events-none")
        }
      }
    })
  }
}
