import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["addLink", "template"]

  addLink(event) {
    event.preventDefault()

    const content = this.templateTarget.innerHTML.replace(/TEMPLATE_RECORD/g, new Date().valueOf())
    this.addLinkTarget.insertAdjacentHTML('afterend', content)
  }

  removeLink(event) {
    event.preventDefault()

    const item = event.target.closest("fieldset")
    item.querySelector("input[name*='_destroy']").value = true
    item.style.display = "none"
  }
}