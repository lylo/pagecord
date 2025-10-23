import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slider"]

  connect() {
    this.scrollTimeout = null
    this.isHovering = false
    this.animationFrame = null
    this.position = 0
    this.speed = 0.5 // pixels per frame

    // Disable CSS animation, use JS instead
    this.sliderTarget.style.animation = 'none'

    // Clone all cards for infinite scroll
    const originalCards = Array.from(this.sliderTarget.children)
    originalCards.forEach(card => {
      const clone = card.cloneNode(true)
      this.sliderTarget.appendChild(clone)
    })

    // Calculate width after cloning
    requestAnimationFrame(() => {
      // Calculate exact width of original cards (not scrollWidth which includes padding)
      const originalWidth = Array.from(this.sliderTarget.children)
        .slice(0, this.sliderTarget.children.length / 2)
        .reduce((total, card) => total + card.offsetWidth + 24, 0) // 24px gap-6

      this.resetPoint = originalWidth

      // Start animation
      this.startAnimation()
    })
  }

  startAnimation() {
    const animate = () => {
      if (!this.isHovering && !this.scrollTimeout) {
        this.position -= this.speed

        // Reset cleanly to 0 (no cumulative offset drift)
        if (Math.abs(this.position) >= this.resetPoint) {
          this.position = 0
        }

        this.sliderTarget.style.transform = `translateX(${this.position}px)`
      }

      this.animationFrame = requestAnimationFrame(animate)
    }

    this.animationFrame = requestAnimationFrame(animate)
  }

  scroll(event) {
    // User is manually scrolling - pause temporarily
    this.isHovering = true

    // Clear existing timeout
    clearTimeout(this.scrollTimeout)

    // Resume animation after user stops scrolling
    this.scrollTimeout = setTimeout(() => {
      if (!this.isHovering) {
        this.scrollTimeout = null
      }
    }, 1000)
  }

  pause() {
    // Pause on hover
    this.isHovering = true
  }

  resume() {
    // Resume on mouse leave
    this.isHovering = false

    // Clear any pending scroll timeout
    clearTimeout(this.scrollTimeout)
    this.scrollTimeout = null
  }

  disconnect() {
    clearTimeout(this.scrollTimeout)
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame)
    }
  }
}
