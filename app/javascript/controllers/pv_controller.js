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

    const data = new FormData()
    if (this.postTokenValue) data.append('post_token', this.postTokenValue)

    if (document.referrer) data.append('referrer', document.referrer)

    data.append('path', window.location.pathname + window.location.search);

    try {
      navigator.sendBeacon(this.pthValue, data)
    } catch (_) {}
  }
}
