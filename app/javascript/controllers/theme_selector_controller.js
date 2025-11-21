import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["customThemeFields"]

  connect() {
    this.toggleCustomThemeFields()
  }

  selectTheme() {
    this.toggleCustomThemeFields()
  }

  toggleCustomThemeFields() {
    const selectedTheme = this.element.querySelector('input[name="blog[theme]"]:checked').value
    if (selectedTheme === "custom") {
      this.customThemeFieldsTarget.classList.remove("hidden")
    } else {
      this.customThemeFieldsTarget.classList.add("hidden")
    }
  }
}
