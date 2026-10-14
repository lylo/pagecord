import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "subdomain", "signature", "code", "stampCode"]

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

  codeChanged() {
    if (this.hasStampCodeTarget) this.stampCodeTarget.textContent = this.codeTarget.value.trim().toUpperCase().slice(0, 10)
  }

  #slug(name) {
    return name.normalize("NFKD").toLowerCase().replace(/[^a-z0-9]/g, "").slice(0, 20)
  }
}
