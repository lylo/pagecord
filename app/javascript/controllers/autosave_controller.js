import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["title", "content"]
  static values = { key: String }

  connect() {
    this.restore()

    if (this.hasTitleTarget) {
      this.titleTarget.addEventListener("input", () => {
        this.save()
      })
    }

    if (this.hasContentTarget) {
      this.contentTarget.addEventListener("lexxy:change", () => {
        this.save()
      })
    }

    this.element.addEventListener("submit", () => this.clear())
  }

  save() {
    const data = {
      title: this.titleTarget?.value,
      content: this.contentTarget?.value
    }

    localStorage.setItem(this.keyValue, JSON.stringify(data))
  }

  restore() {
    const raw = localStorage.getItem(this.keyValue)
    if (!raw) return

    try {
      const { title, content } = JSON.parse(raw)

      if (title && this.hasTitleTarget && !this.titleTarget.value.trim()) {
        this.titleTarget.value = title
      }

      if (content && this.hasContentTarget) {
        this.contentTarget.value = content
      }
    } catch {
      this.clear()
    }
  }

  cancel(event) {
    const isEdit = this.keyValue.startsWith("draft-post-") && !this.keyValue.endsWith("new")
    const hasDraft = !!localStorage.getItem(this.keyValue)

    if (isEdit && hasDraft) {
      const confirmed = confirm("You have unsaved changes. Are you sure you want to lose them?")
      if (!confirmed) {
        event.preventDefault()
        return
      }
    }

    this.clear()
  }

  clear() {
    localStorage.removeItem(this.keyValue)
  }

}
