import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    fetch(this.urlValue, { method: "POST" }).catch(() => {})
  }
}
