import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overrideFields", "customColourFields"]

  connect() {
    this.toggle()
  }

  toggle() {
    const overrideChecked = this.element.querySelector("#override_appearance")?.checked
    this.overrideFieldsTarget.classList.toggle("hidden", !overrideChecked)

    const selectedTheme = this.element.querySelector('input[name$="[theme]"]:checked')?.value || ""
    this.customColourFieldsTarget.classList.toggle("hidden", selectedTheme !== "custom")
  }
}
