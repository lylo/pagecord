import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

const SHORTCUTS = { j: "next", k: "previous", n: "not-spam", s: "spam", r: "remove", o: "open" }

export default class extends Controller {
  static targets = ["row"]

  key(event) {
    if (event.metaKey || event.ctrlKey || event.altKey || event.shiftKey) return
    if (event.target.closest("input, textarea, select, [contenteditable]")) return

    const shortcut = SHORTCUTS[event.key]
    if (!shortcut) return

    event.preventDefault()
    if (shortcut === "next") return this.#move(1)
    if (shortcut === "previous") return this.#move(-1)

    this.#selected?.querySelector(`[data-shortcut="${shortcut}"]`)?.click()
  }

  rowTargetDisconnected(row) {
    if (!this.element.isConnected) return
    if (!this.hasRowTarget) return Turbo.visit(window.location.href, { action: "replace" })

    if (row === this.#selected) {
      this.#selected = null
      this.#select(this.rowTargets[Math.min(this.#index, this.rowTargets.length - 1)])
    }
  }

  #selected = null
  #index = 0

  #move(step) {
    if (!this.hasRowTarget) return

    const index = this.#selected ? this.rowTargets.indexOf(this.#selected) + step : 0
    this.#select(this.rowTargets[Math.max(0, Math.min(index, this.rowTargets.length - 1))])
  }

  #select(row) {
    this.#selected?.removeAttribute("data-selected")
    this.#selected = row
    this.#index = this.rowTargets.indexOf(row)
    row.setAttribute("data-selected", "")
    row.scrollIntoView({ block: "nearest", behavior: "smooth" })
  }
}
