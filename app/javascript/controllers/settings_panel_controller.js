import { Controller } from "@hotwired/stimulus"

const WORDS_PER_MINUTE = 230
const BLOCKS = "p, li, h1, h2, h3, h4, h5, h6, blockquote, pre, td, th, br"

export default class extends Controller {
  static targets = ["panel", "tags", "wordCount", "characterCount", "readingTime"]

  connect() {
    if (this.panelTarget.querySelector(".field-error:not(:empty)")) this.open()
  }

  open() {
    this.previouslyFocused = document.activeElement
    this.previousRange = this.caretRange()
    this.panelTarget.setAttribute("data-open", "")

    // Focus the first field once the drawer is on screen - it's still
    // visibility:hidden on the first frame, so focus wouldn't take
    requestAnimationFrame(() => requestAnimationFrame(() => this.firstField?.focus()))

    this.updateStats()
  }

  close() {
    this.panelTarget.removeAttribute("data-open")
    this.previouslyFocused?.focus()
    this.restoreCaret()
  }

  // Inputs remember their cursor, but focusing the editor drops the caret at
  // the start, so put the selection back where the writer left it
  caretRange() {
    if (!this.previouslyFocused?.isContentEditable) return null

    const selection = window.getSelection()
    return selection?.rangeCount ? selection.getRangeAt(0).cloneRange() : null
  }

  restoreCaret() {
    if (!this.previousRange) return

    const selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange(this.previousRange)
  }

  reveal(event) {
    if (this.panelTarget.hasAttribute("data-open")) return

    this.open()
    requestAnimationFrame(() => requestAnimationFrame(() => event.target.reportValidity()))
  }

  toggle() {
    this.panelTarget.hasAttribute("data-open") ? this.close() : this.open()
  }

  get firstField() {
    return this.panelTarget.querySelector("input:not([type=hidden]), textarea, select, [contenteditable]:not([contenteditable=false])")
  }

  updateStats() {
    const text = this.#writtenText
    const words = this.#segments(text, "word").filter(segment => segment.isWordLike).length

    this.wordCountTarget.textContent = words.toLocaleString("en")
    this.characterCountTarget.textContent = this.#segments(text.replace(/\n/g, ""), "grapheme").length.toLocaleString("en")
    this.readingTimeTarget.textContent = `${Math.ceil(words / WORDS_PER_MINUTE)} min`
  }

  #segments(text, granularity) {
    return [...new Intl.Segmenter(undefined, { granularity }).segment(text)]
  }

  get #writtenText() {
    const html = this.element.querySelector("lexxy-editor")?.value || ""
    const body = new DOMParser().parseFromString(html, "text/html").body

    body.querySelectorAll("action-text-attachment").forEach(attachment => attachment.remove())
    body.querySelectorAll(BLOCKS).forEach(block => block.append("\n"))

    return body.textContent
  }

  refreshTags(event) {
    const tags = event.target.value.split(",").map(tag => tag.trim()).filter(Boolean)
    const labels = tags.slice(0, 3).map(tag => `#${tag}`)
    if (tags.length > 3) labels.push(`+${tags.length - 3} more`)
    this.tagsTarget.replaceChildren(...labels.map(text => Object.assign(document.createElement("span"), { textContent: text })))
  }

  dismiss(event) {
    if (!this.panelTarget.hasAttribute("data-open")) return

    event.preventDefault()
    this.close()
  }
}
