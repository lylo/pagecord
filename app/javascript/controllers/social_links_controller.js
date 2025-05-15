import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["addLink", "template", "platform" ]
  static values = {
    rssFeedUrl: { type: String },
    platformUrls: { type: Object, default: {} }
  }

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
    const newPlatform = platformSelect.value

    if (platformId) {
      const urlId = platformId.replace("_platform", "_url")
      const urlInput = document.getElementById(urlId)

      if (urlInput) {
        // Before changing the URL input value, save the current one with its platform
        const oldPlatform = event.target.dataset.previousPlatform
        if (oldPlatform && urlInput.value) {
          const updatedUrls = { ...this.platformUrlsValue }
          updatedUrls[oldPlatform] = urlInput.value
          this.platformUrlsValue = updatedUrls
        }

        // Store the new platform value for next change
        event.target.dataset.previousPlatform = newPlatform

        // Set the appropriate URL value
        if (newPlatform === "RSS") {
          urlInput.value = this.rssFeedUrlValue
        } else if (this.platformUrlsValue[newPlatform]) {
          urlInput.value = this.platformUrlsValue[newPlatform]
        } else {
          urlInput.value = ""
        }
        
        // Update placeholder text based on platform
        if (newPlatform === "Email") {
          urlInput.placeholder = "Enter your email address"
        } else {
          urlInput.placeholder = "Enter full URL e.g. https://example.com"
        }
      }
    }
  }
}