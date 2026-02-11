import { Controller } from "@hotwired/stimulus"
import Tagify from "@yaireo/tagify"

// Connects to data-controller="tags-input"
export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.initializeTagify()
  }

  disconnect() {
    if (this.tagify) {
      this.tagify.destroy()
    }
  }

  initializeTagify() {
    // Simple Tagify configuration matching competitor's approach
    this.tagify = new Tagify(this.inputTarget, {
      // Transform tags to lowercase
      transformTag: (tagData) => {
        tagData.value = tagData.value.toLowerCase()
      },

      // Validate tags (letters including unicode, numbers, and hyphens)
      validate: (tagData) => {
        return /^[\p{L}\p{N}-]+$/u.test(tagData.value)
      },

      // Maximum number of tags
      maxTags: 10,

      // Disable dropdown
      dropdown: {
        enabled: false,
        highlightFirst: false
      },

      // Disable autocomplete
      autoComplete: {
        enabled: false
      },

      // Don't allow duplicates
      duplicates: false,

      // Format output as simple comma-separated string instead of JSON
      originalInputValueFormat: valuesArr => valuesArr.map(item => item.value).join(', ')
    })
  }
}
