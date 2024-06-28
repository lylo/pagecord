import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.classList.add('animate-fadeIn')
    setTimeout(() => {
      this.element.classList.replace('animate-fadeIn', 'animate-fadeOut')
    }, 3000)
  }
}