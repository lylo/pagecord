
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["heart"]

  pulse(event) {
    const heart = this.heartTarget

    heart.style.fill = "#ef4444"
    heart.style.stroke = "#ef4444"

    heart.classList.add("animate-pulse-grow")

    setTimeout(() => {
      heart.classList.remove("animate-pulse-grow")
    }, 500)
  }
}
