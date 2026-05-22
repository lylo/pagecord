import { Controller } from "@hotwired/stimulus"
import Tagify from "@yaireo/tagify"

// Connects to data-controller="tags-input"
export default class extends Controller {
  static targets = ["input"]
  static values = { suggestions: { type: Array, default: [] } }

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

      // Autocomplete from existing tags
      whitelist: this.suggestionsValue,
      dropdown: {
        enabled: 1,
        maxItems: 10,
        closeOnSelect: false,
        highlightFirst: true
      },

      // Don't allow duplicates
      duplicates: false,

      // Format output as simple comma-separated string instead of JSON
      originalInputValueFormat: valuesArr => valuesArr.map(item => item.value).join(', ')
    })
  }
}
