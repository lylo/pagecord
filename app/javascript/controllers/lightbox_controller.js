import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
    // Find all images in article content and make them clickable
    this.element.querySelectorAll('article img').forEach(img => {
      img.style.cursor = 'zoom-in'
      img.addEventListener('click', this.openLightbox.bind(this, img))
    })

    // Handle keyboard events
    this.handleKeydown = this.handleKeydown.bind(this)
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleKeydown)
    if (this.modal) {
      this.modal.remove()
    }
  }

  openLightbox(img, event) {
    event.preventDefault()

    // Create lightbox modal if it doesn't exist
    if (!this.modal) {
      this.createModal()
    }

    // Set the image source to the clicked image
    this.lightboxImage.src = img.src
    this.lightboxImage.alt = img.alt || ''

    // Show the modal with smooth animation - prevent scrolling on mobile too
    // Save current scroll position
    this.scrollY = window.scrollY
    document.body.style.overflow = 'hidden'
    document.body.style.position = 'fixed'
    document.body.style.top = `-${this.scrollY}px`
    document.body.style.width = '100%'

    // Use requestAnimationFrame to ensure the modal is rendered before adding show class
    requestAnimationFrame(() => {
      this.modal.classList.add('show')
    })

    // Add keyboard listener
    document.addEventListener('keydown', this.handleKeydown)
  }

  closeLightbox(event) {
    if (event) {
      event.preventDefault()
    }

    if (this.modal) {
      this.modal.classList.remove('show')
      // Restore scroll position
      document.body.style.overflow = ''
      document.body.style.position = ''
      document.body.style.top = ''
      document.body.style.width = ''
      window.scrollTo(0, this.scrollY || 0)
    }

    // Remove keyboard listener
    document.removeEventListener('keydown', this.handleKeydown)
  }

  handleKeydown(event) {
    // Close on Escape or any key press
    if (event.key === 'Escape' || event.type === 'keydown') {
      this.closeLightbox()
    }
  }

  handleBackdropClick(event) {
    // Close on any click within the lightbox (except the close button)
    if (event.target !== this.closeButton) {
      this.closeLightbox()
    }
  }

  createModal() {
    // Main lightbox container
    const modal = document.createElement('div')
    modal.className = 'lightbox'
    modal.addEventListener('click', this.handleBackdropClick.bind(this))

    const closeButton = document.createElement('button')
    closeButton.className = 'lightbox__close btn--icon-round'
    closeButton.innerHTML = `
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <line x1="18" y1="6" x2="6" y2="18"></line>
        <line x1="6" y1="6" x2="18" y2="18"></line>
      </svg>
    `
    closeButton.addEventListener('click', this.closeLightbox.bind(this))

    // Content wrapper
    const contentWrapper = document.createElement('div')
    contentWrapper.className = 'lightbox__content'

    // Image element
    const image = document.createElement('img')

    contentWrapper.appendChild(image)
    modal.appendChild(closeButton)
    modal.appendChild(contentWrapper)
    document.body.appendChild(modal)

    // Store references for later use
    this.modal = modal
    this.lightboxImage = image
    this.closeButton = closeButton
    this.contentWrapper = contentWrapper
  }
}