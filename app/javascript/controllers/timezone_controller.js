import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["timeZone"]

  connect() {
    this.timeZoneTarget.value = Intl.DateTimeFormat().resolvedOptions().timeZone
  }
}
