import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pageFields", "customFields", "socialFields", "searchFields", "pageRadio", "customRadio", "socialRadio", "searchRadio", "platform", "url"]
  static values = {
    rssFeedUrl: { type: String }
  }

  connect() {
    this.toggleFields()
  }

  handlePlatformChange(event) {
    const platform = event.target.value

    if (this.hasUrlTarget) {
      if (platform === "RSS") {
        this.urlTarget.value = this.rssFeedUrlValue
      } else if (!event.target.dataset.skipClear) {
        this.urlTarget.value = ""
      }

      if (platform === "Email") {
        this.urlTarget.placeholder = "Enter your email address"
      } else {
        this.urlTarget.placeholder = "https://..."
      }
    }
  }

  toggleFields() {
    if (this.pageRadioTarget.checked) {
      this.showOnly(this.pageFieldsTarget)
    } else if (this.customRadioTarget.checked) {
      this.showOnly(this.customFieldsTarget)
    } else if (this.hasSearchRadioTarget && this.searchRadioTarget.checked) {
      this.showOnly(this.searchFieldsTarget)
    } else {
      this.showOnly(this.socialFieldsTarget)
    }
  }

  showOnly(activeTarget) {
    [this.pageFieldsTarget, this.customFieldsTarget, this.socialFieldsTarget, this.searchFieldsTarget].forEach(target => {
      if (target === activeTarget) {
        target.classList.remove("hidden")
        this.enableFields(target)
      } else {
        target.classList.add("hidden")
        this.disableFields(target)
      }
    })
  }

  disableFields(container) {
    container.querySelectorAll("input, select").forEach(field => {
      field.disabled = true
    })
  }

  enableFields(container) {
    container.querySelectorAll("input, select").forEach(field => {
      field.disabled = false
    })
  }
}
