import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["heart"]

  pulse() {
    this.heartTarget.style.fill = "#ef4444"
    this.heartTarget.style.stroke = "#ef4444"
    this.heartTarget.classList.add("animate-pulse-grow")

    setTimeout(() => {
      this.heartTarget.classList.remove("animate-pulse-grow")
    }, 500)
  }
}
