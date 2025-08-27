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
   
    if (document.referrer) data.append('referrer', document.referrer)

    data.append('path', window.location.pathname + window.location.search);

    try {
      navigator.sendBeacon(this.hitUrlValue, data)
    } catch (_) {}
  }
}
