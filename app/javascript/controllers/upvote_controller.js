import { Controller } from "@hotwired/stimulus"

let pending = new Map()
let scheduled = false

function fetchBatchStatuses() {
  const batch = pending
  pending = new Map()
  scheduled = false

  const params = new URLSearchParams()
  for (const token of batch.keys()) params.append("tokens[]", token)

  fetch(`/upvotes/statuses?${params}`)
    .then(response => response.json())
    .then(statuses => {
      batch.forEach((callback, token) => {
        if (statuses[token]) callback()
      })
    })
}

export default class extends Controller {
  static targets = ["heart"]
  static values = { token: String }

  connect() {
    if (this.hasTokenValue) {
      pending.set(this.tokenValue, () => this.fill())

      if (!scheduled) {
        scheduled = true
        queueMicrotask(fetchBatchStatuses)
      }
    }
  }

  pulse(event) {
    if (this.upvoted) {
      event.preventDefault()
      return
    }

    this.fill()
    this.heartTarget.classList.add("animate-pulse-grow")
    setTimeout(() => {
      this.heartTarget.classList.remove("animate-pulse-grow")
    }, 500)
  }

  fill() {
    this.upvoted = true
    this.heartTarget.style.fill = "#ef4444"
    this.heartTarget.style.stroke = "#ef4444"
  }
}
