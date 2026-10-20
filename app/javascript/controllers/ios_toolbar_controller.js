import { Controller } from "@hotwired/stimulus"

const CARET_MARGIN = 8

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

    this.element.addEventListener("focusin", this.#revealCaretWhenKeyboardOpens)
  }

  disconnect() {
    if (this.rafId) {
      cancelAnimationFrame(this.rafId)
    }

    this.element.removeEventListener("focusin", this.#revealCaretWhenKeyboardOpens)
    window.visualViewport?.removeEventListener("resize", this.#revealCaret)
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

  #revealCaretWhenKeyboardOpens = () => {
    window.visualViewport?.addEventListener("resize", this.#revealCaret, { once: true })
  }

  #revealCaret = () => {
    const caret = this.#caretRect()
    if (!caret) return

    const overlap = this.toolbar.getBoundingClientRect().bottom - caret.top
    if (overlap > 0) window.scrollBy(0, -(overlap + CARET_MARGIN))
  }

  #caretRect() {
    const selection = window.getSelection()
    if (!selection.rangeCount || !this.element.contains(selection.anchorNode)) return

    const range = selection.getRangeAt(0)
    const node = range.startContainer
    const element = node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement

    return range.getClientRects()[0] ?? element.getBoundingClientRect()
  }
}
