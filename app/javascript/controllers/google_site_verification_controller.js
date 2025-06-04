import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  paste(event) {
    const clipboardData = event.clipboardData || window.clipboardData
    const pastedText = clipboardData.getData('text')

    const metaTagRegex = /<meta\s+name\s*=\s*["']google-site-verification["']\s+content\s*=\s*["']([^"']+)["'][^>]*>/i
    const match = pastedText.match(metaTagRegex)

    if (match && match[1].trim()) {
      event.preventDefault()

      const verificationCode = match[1]
      this.element.value = verificationCode

      this.element.dispatchEvent(new Event('input', { bubbles: true }))
    }
  }
}
