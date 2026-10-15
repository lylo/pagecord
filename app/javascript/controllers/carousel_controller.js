import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "set" ]
  static values = { duration: { type: Number, default: 60000 } }

  connect() {
    this.position = this.element.scrollLeft
    if (!matchMedia("(prefers-reduced-motion: reduce)").matches) this.frame = requestAnimationFrame(this.tick)
  }

  disconnect() {
    cancelAnimationFrame(this.frame)
  }

  pause() {
    this.paused = true
  }

  resume() {
    this.paused = false
  }

  tick = (time) => {
    const width = this.setTarget.offsetWidth
    const elapsed = time - (this.lastTime ?? time)
    this.lastTime = time

    if (Math.abs(this.element.scrollLeft - this.position) > 1) this.position = this.element.scrollLeft
    if (!this.paused) this.position += width * elapsed / this.durationValue
    if (this.position >= width) this.position -= width

    this.element.scrollLeft = this.position
    this.frame = requestAnimationFrame(this.tick)
  }
}
