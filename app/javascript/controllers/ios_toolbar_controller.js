import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toolbar"]

  connect() {
    // Only run on iOS
    if (!this.isIOS()) return

    this.toolbar = this.hasToolbarTarget ? this.toolbarTarget : this.element.querySelector("lexxy-toolbar")
    if (!this.toolbar) return

    // Start the layout loop
    this.boundLoop = this.loop.bind(this)
    this.rafId = requestAnimationFrame(this.boundLoop)
  }

  disconnect() {
    if (this.rafId) {
      cancelAnimationFrame(this.rafId)
    }
  }

  isIOS() {
    return (
      (/iPad|iPhone|iPod/.test(navigator.userAgent)) ||
      (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)
    ) && !window.MSStream
  }

  loop() {
    if (window.visualViewport) {
      const offset = window.visualViewport.offsetTop
      
      // We check if the value changed to avoid unnecessary style recalculations
      if (this.lastOffset !== offset) {
        this.toolbar.style.top = `${offset}px`
        this.lastOffset = offset
      }
    }

    this.rafId = requestAnimationFrame(this.boundLoop)
  }
}
