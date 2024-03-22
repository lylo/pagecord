import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "response" ]

  show() {
    setTimeout(() => {
      this.responseTarget.innerHTML = ""
    }, 2000)
  }
}