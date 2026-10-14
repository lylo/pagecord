import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "subdomain", "signature"]

  connect() {
    this.subdomainEdited = this.subdomainTarget.value !== "" && this.subdomainTarget.value !== this.#slug(this.nameTarget.value)
  }

  nameChanged() {
    this.signatureTarget.textContent = this.nameTarget.value
    if (!this.subdomainEdited) this.subdomainTarget.value = this.#slug(this.nameTarget.value)
  }

  subdomainChanged() {
    this.subdomainEdited = this.subdomainTarget.value !== ""
  }

  #slug(name) {
    return name.normalize("NFKD").toLowerCase().replace(/[^a-z0-9]/g, "").slice(0, 20)
  }
}
