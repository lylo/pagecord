import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["section"]

  connect() {
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
  }

  toggle(event) {
    event.preventDefault()
    this.toggleById(event.currentTarget.dataset.toggleTarget)
  }

  toggleById(sectionId) {
    const section = this.sectionTargets.find(el => el.dataset.section === sectionId)

    if (section) {
      const isHidden = section.classList.contains("hidden")
      section.classList.toggle("hidden")

      if (isHidden) {
        this.focusInput(section)
      }
    }
  }

  focusInput(section) {
    // Tagify uses a contenteditable span instead of an input
    const tagifyInput = section.querySelector(".tagify__input")
    if (tagifyInput) {
      tagifyInput.focus()
      return
    }

    const input = section.querySelector("input, textarea, select")
    if (input) {
      input.focus()
    }
  }

  get dropdownMenu() {
    return this.element.querySelector("[data-toggle-target='element']")
  }

  get isMenuOpen() {
    return this.dropdownMenu && !this.dropdownMenu.classList.contains("hidden")
  }

  toggleMenu() {
    const toggleLink = this.element.querySelector("[data-action*='toggle#toggle']")
    if (toggleLink) {
      toggleLink.click()
    }
  }

  closeMenu() {
    if (this.isMenuOpen) {
      this.dropdownMenu.classList.add("hidden")
    }
  }

  handleKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === ".") {
      event.preventDefault()
      this.toggleMenu()
      return
    }

    if (this.isMenuOpen) {
      const shortcuts = {
        "s": "slug",
        "v": "visibility",
        "t": "tags",
        "p": "published-at",
        "c": "canonical-url"
      }

      const sectionId = shortcuts[event.key.toLowerCase()]
      if (sectionId) {
        event.preventDefault()
        this.closeMenu()
        this.toggleById(sectionId)
      }

      if (event.key === "Escape") {
        event.preventDefault()
        this.closeMenu()
      }

      if (event.key === "Backspace") {
        const deleteButton = this.element.querySelector("[data-delete-target]")
        if (deleteButton) {
          event.preventDefault()
          this.closeMenu()
          deleteButton.click()
        }
      }
    }
  }
}
