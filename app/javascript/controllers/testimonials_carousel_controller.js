import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slider"]

  connect() {
    this.scrollTimeout = null
    this.isHovering = false

    // Store original cards for cloning
    this.originalCards = Array.from(this.sliderTarget.children).map(card => card.cloneNode(true))

    // Add enough duplicates to start
    for (let i = 0; i < 3; i++) {
      this.appendSet()
    }

    // Use CSS scroll for smooth animation
    this.startScroll()
  }

  appendSet() {
    this.originalCards.forEach(card => {
      this.sliderTarget.appendChild(card.cloneNode(true))
    })
  }

  startScroll() {
    let position = 0

    // Calculate the width of one set for looping
    requestAnimationFrame(() => {
      const firstCard = this.sliderTarget.children[0]
      this.oneSetWidth = firstCard.offsetWidth * this.originalCards.length + (24 * this.originalCards.length) // cards + gaps
    })

    const scroll = () => {
      if (!this.isHovering && !this.scrollTimeout && this.oneSetWidth) {
        position -= 0.5

        // Loop position when we've scrolled past one set
        if (Math.abs(position) >= this.oneSetWidth) {
          position += this.oneSetWidth
        }

        this.sliderTarget.style.transform = `translateX(${position}px)`
      }

      this.animationFrame = requestAnimationFrame(scroll)
    }

    this.animationFrame = requestAnimationFrame(scroll)
  }

  scroll(event) {
    this.isHovering = true
    clearTimeout(this.scrollTimeout)
    this.scrollTimeout = setTimeout(() => {
      this.isHovering = false
      this.scrollTimeout = null
    }, 1000)
  }

  pause() {
    this.isHovering = true
  }

  resume() {
    this.isHovering = false
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
