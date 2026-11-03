import { Controller } from "@hotwired/stimulus"

let request

export default class extends Controller {
  static values = { url: String }

  prepare() {
    request ||= fetch(this.urlValue, { method: "POST" }).catch(() => { request = null })
  }
}
