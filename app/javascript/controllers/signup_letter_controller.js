import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "subdomain", "address", "code", "stampCode"]

  connect() {
    if (this.hasSubdomainTarget) {
      this.followingName = this.subdomainTarget.value === "" || this.subdomainTarget.value === this.#slug
      this.nameChanged()
    }
  }

  nameChanged() {
    if (this.hasSubdomainTarget && this.followingName) this.subdomainTarget.value = this.#slug
    if (this.hasAddressTarget) this.addressTarget.textContent = this.#slug && `${this.#slug}.pagecord.com`
  }

  subdomainChanged() {
    this.followingName = this.subdomainTarget.value === ""
  }

  codeChanged() {
    if (this.hasStampCodeTarget) this.stampCodeTarget.textContent = this.codeTarget.value.trim().toUpperCase().slice(0, 10)
  }

  get #slug() {
    return this.nameTarget.value.normalize("NFKD").toLowerCase().replace(/[^a-z0-9]/g, "").slice(0, 20)
  }
}
