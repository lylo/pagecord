import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["heart"]
  static values = { url: String }

  connect() {
    if (this.hasUrlValue) {
      fetch(this.urlValue)
        .then(response => response.json())
        .then(({ upvoted }) => {
          if (upvoted) this.fill()
        })
    }
  }

  pulse() {
    this.fill()
    this.heartTarget.classList.add("animate-pulse-grow")
    setTimeout(() => {
      this.heartTarget.classList.remove("animate-pulse-grow")
    }, 500)
  }

  fill() {
    this.heartTarget.style.fill = "#ef4444"
    this.heartTarget.style.stroke = "#ef4444"
  }
}
