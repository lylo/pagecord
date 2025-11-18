import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pageFields", "customFields", "socialFields", "pageRadio", "customRadio", "socialRadio", "platform", "url"]
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
      this.showPageFields()
    } else if (this.customRadioTarget.checked) {
      this.showCustomFields()
    } else {
      this.showSocialFields()
    }
  }

  showPageFields() {
    this.pageFieldsTarget.classList.remove("hidden")
    this.enableFields(this.pageFieldsTarget)
    this.customFieldsTarget.classList.add("hidden")
    this.disableFields(this.customFieldsTarget)
    this.socialFieldsTarget.classList.add("hidden")
    this.disableFields(this.socialFieldsTarget)
  }

  showCustomFields() {
    this.pageFieldsTarget.classList.add("hidden")
    this.disableFields(this.pageFieldsTarget)
    this.customFieldsTarget.classList.remove("hidden")
    this.enableFields(this.customFieldsTarget)
    this.socialFieldsTarget.classList.add("hidden")
    this.disableFields(this.socialFieldsTarget)
  }

  showSocialFields() {
    this.pageFieldsTarget.classList.add("hidden")
    this.disableFields(this.pageFieldsTarget)
    this.customFieldsTarget.classList.add("hidden")
    this.disableFields(this.customFieldsTarget)
    this.socialFieldsTarget.classList.remove("hidden")
    this.enableFields(this.socialFieldsTarget)
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
