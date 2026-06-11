import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]
  static values = {
    shortcut: String
  }

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  openFromShortcut(event) {
    if (event.defaultPrevented) return
    if (!this.hasShortcutValue || this.typingTarget(event.target) || !this.matchesShortcut(event)) return
    if (event.metaKey || event.ctrlKey || event.altKey) return

    event.preventDefault()
    if (!this.dialogTarget.open) this.open()
  }

  matchesShortcut(event) {
    return this.shortcutValue === "?" ? (event.key === "?" || (event.key === "/" && event.shiftKey)) : event.key === this.shortcutValue
  }

  typingTarget(target) {
    return target.closest("input, textarea, select, [contenteditable='true'], lexxy-editor, trix-editor")
  }
}
