import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    duration: { type: Number, default: 3000 }
  }

  connect() {
    this.element.classList.remove('hidden')
    this.element.classList.add('animate-fadeIn')
    setTimeout(() => {
      this.element.classList.replace('animate-fadeIn', 'animate-fadeOut')

      // Listen for when the fade-out animation ends
      this.element.addEventListener('animationend', () => {
        this.element.remove(); // Remove the element from the DOM
      }, { once: true });

    }, this.durationValue)
  }
}