import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "section" ]

  showSection(event) {
    event.preventDefault()

    const sectionId = event.currentTarget.dataset.toggleTarget
    const section = this.sectionTargets.find(el => el.dataset.section === sectionId)

    if (section) {
      section.classList.remove("hidden")
    }
 }
}