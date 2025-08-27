import { Controller } from "@hotwired/stimulus"

// Analytics tracking controller for Pagecord blogs
// Tracks page views via navigator.sendBeacon, silently fails if unsupported
export default class extends Controller {
  static values = { 
    hitUrl: String,
    postToken: String 
  }

  connect() {
    this.trackPageView()
  }

  trackPageView() {
    if (!navigator.sendBeacon) return

    const data = new FormData()
    if (this.postTokenValue) data.append('post_token', this.postTokenValue)
    // Include referrer if desired
    if (document.referrer) data.append('referrer', document.referrer)

    // Send the beacon; fail silently if any error occurs
    try {
      navigator.sendBeacon(this.hitUrlValue, data)
    } catch (_) {}
  }
}
