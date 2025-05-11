import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["addLink", "template", "platform" ]
  static values = { rssFeedUrl: { type: String } }

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

  handlePlatformChange(event) {
    const platformSelect = event.target
    const platformId = platformSelect.id

    if (platformId) {
      const urlId = platformId.replace("_platform", "_url")
      const urlInput = document.getElementById(urlId)

      if (urlInput) {
        if (platformSelect.value === "RSS") {
          urlInput.value = this.rssFeedUrlValue
        } else {
          urlInput.value = ""
        }
      }
    }
  }
}