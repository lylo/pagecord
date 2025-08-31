
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["heart"]

  pulse(event) {
    const heart = this.heartTarget
    heart.classList.add("animate-pulse-grow", "text-red-500")

    setTimeout(() => {
      heart.classList.remove("animate-pulse-grow", "text-red-500")
    }, 500)
  }
}
