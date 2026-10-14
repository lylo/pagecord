import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "subdomain"]

  connect() {
    this.followingName = this.subdomainTarget.value === "" || this.subdomainTarget.value === this.#slug
  }

  nameChanged() {
    if (this.followingName) this.subdomainTarget.value = this.#slug
  }

  subdomainChanged() {
    this.followingName = this.subdomainTarget.value === ""
  }

  get #slug() {
    return this.nameTarget.value.normalize("NFKD").toLowerCase().replace(/[^a-z0-9]/g, "").slice(0, 20)
  }
}
