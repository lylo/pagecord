import { Controller } from "@hotwired/stimulus"

// Holding Shift reveals each element's data-hotkey; Shift plus that key clicks it.
// In a text field, Shift is for typing, so a double-tap of Shift reveals them instead.
export default class extends Controller {
  keydown(event) {
    if (event.key === "Shift") {
      if (event.repeat) return
      this.shiftHeld = true
      this.interrupted = event.metaKey || event.ctrlKey || event.altKey
      if (!this.interrupted && !this.active && !this.typing) this.enter()
    } else if (this.active) {
      this.press(event)
    } else {
      if (this.shiftHeld) this.interrupted = true
      this.taps = 0
    }
  }

  keyup(event) {
    if (event.key !== "Shift") return
    this.shiftHeld = false

    if (this.active) {
      this.exit()
    } else if (this.typing && !this.interrupted) {
      this.taps = (this.taps || 0) + 1
      clearTimeout(this.tapTimer)
      this.tapTimer = setTimeout(() => this.taps = 0, 500)
      if (this.taps === 2) this.enter({ expiring: true })
    }
  }

  exit() {
    this.active = false
    this.taps = 0
    clearTimeout(this.revealTimer)
    clearTimeout(this.expiryTimer)
    this.element.removeAttribute("data-hotkey-mode")
  }

  enter({ expiring = false } = {}) {
    this.active = true
    this.revealTimer = setTimeout(() => this.element.setAttribute("data-hotkey-mode", ""), 150)
    if (expiring) this.expiryTimer = setTimeout(() => this.exit(), 3000)
  }

  press(event) {
    if (event.key === "Escape" || event.metaKey || event.ctrlKey || event.altKey || !this.shiftHeld) return this.exit()

    const target = this.find(this.keyFor(event))
    if (target) {
      event.preventDefault()
      target.click()
    }
  }

  find(key) {
    const scope = [ ...document.querySelectorAll("dialog[open]") ].at(-1) ?? document
    const targets = [ ...scope.querySelectorAll(`[data-hotkey="${CSS.escape(key)}"]`) ]
    return targets.find(target => target.checkVisibility()) ?? targets[0]
  }

  keyFor(event) {
    return (event.code.match(/^Key([A-Z])$/)?.[1] ?? event.key).toLowerCase()
  }

  get typing() {
    const element = document.activeElement
    return element?.isContentEditable || element?.matches("textarea, select, input:not([type=checkbox], [type=radio], [type=submit], [type=reset], [type=file], [type=button])")
  }
}
