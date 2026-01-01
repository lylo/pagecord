import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["heart"]

  connect() {
    if (this.element.dataset.upvoted) {
      this.applyUpvotedStyle()
    }
  }

  pulse() {
    this.applyUpvotedStyle()
    this.heartTarget.classList.add("animate-pulse-grow")

    setTimeout(() => {
      this.heartTarget.classList.remove("animate-pulse-grow")
    }, 500)
  }

  applyUpvotedStyle() {
    this.heartTarget.style.fill = "#ef4444"
    this.heartTarget.style.stroke = "#ef4444"
  }
}
