
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["heart"]

  pulse(event) {
    // stop immediate submit
    event.preventDefault()

    const heart = this.heartTarget
    heart.classList.add("animate-pulse-grow", "text-red-500")

    // after 1s remove animation + submit the form
    setTimeout(() => {
      heart.classList.remove("animate-pulse-grow", "text-red-500")
      this.element.closest("form").requestSubmit()
    }, 500)
  }
}
