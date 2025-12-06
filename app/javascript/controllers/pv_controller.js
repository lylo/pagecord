import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    pth: String,
    postToken: String
  }

  connect() {
    this.pv()
  }

  pv() {
    if (!navigator.sendBeacon) return

    const data = {
      path: window.location.pathname + window.location.search
    }
    if (this.postTokenValue) data.post_token = this.postTokenValue
    if (document.referrer) data.referrer = document.referrer

    try {
      const blob = new Blob([JSON.stringify(data)], { type: 'application/json' })
      navigator.sendBeacon(this.pthValue, blob)
    } catch (_) {}
  }
}
