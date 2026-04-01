import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["title", "content"]
  static values = { key: String }

  connect() {
    this.baseDraft = this.currentDraft()

    if (this.isExistingRecord && this.hasContentTarget && !this.baseDraft.content) {
      customElements.whenDefined(this.contentTarget.localName).then(() => {
        this.baseDraft = this.currentDraft()
        this.restore()
      })
    } else {
      this.restore()
    }

    if (this.hasTitleTarget) {
      this.titleTarget.addEventListener("input", () => this.save())
    }

    if (this.hasContentTarget) {
      this.contentTarget.addEventListener("lexxy:change", () => this.save())
    }

    this.element.addEventListener("submit", () => this.clear())
  }

  save() {
    localStorage.setItem(this.keyValue, JSON.stringify({
      ...this.currentDraft(),
      base: this.baseDraft
    }))
  }

  restore() {
    const draft = this.readDraft()
    if (!draft) return

    if (this.isExistingRecord && !this.canRestoreExistingDraft(draft)) {
      this.clear()
      return
    }

    if (draft.title && this.hasTitleTarget) {
      this.titleTarget.value = draft.title
    }

    if (draft.content && this.hasContentTarget) {
      this.contentTarget.value = draft.content
    }
  }

  cancel(event) {
    if (this.isExistingRecord && this.readDraft()) {
      if (!confirm("You have unsaved changes. Are you sure you want to lose them?")) {
        event.preventDefault()
        return
      }
    }

    this.clear()
  }

  clear() {
    localStorage.removeItem(this.keyValue)
  }

  currentDraft() {
    return {
      title: this.titleTarget?.value || "",
      content: this.contentTarget?.value || ""
    }
  }

  readDraft() {
    const raw = localStorage.getItem(this.keyValue)
    if (!raw) return null

    try {
      return JSON.parse(raw)
    } catch {
      this.clear()
      return null
    }
  }

  get isExistingRecord() {
    return !this.keyValue.endsWith("new")
  }

  // Existing-post drafts are only safe to restore if they were captured from the
  // same saved post state that's being edited now.
  canRestoreExistingDraft(draft) {
    return draft.base &&
      draft.base.title === this.baseDraft.title &&
      draft.base.content === this.baseDraft.content
  }

}
