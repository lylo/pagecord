import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.handleImageClick = this.handleImageClick.bind(this)
    this.handleKeydown = this.handleKeydown.bind(this)

    this.element.querySelectorAll("article img").forEach((img) => {
      if (!this.lightboxEnabledFor(img)) return
      img.style.cursor = "zoom-in"
    })

    this.element.addEventListener("click", this.handleImageClick)
  }

  isMobile() {
    return window.innerWidth <= 768
  }

  lightboxEnabledFor(img) {
    return !this.isMobile() || img.closest(".attachment-gallery")
  }

  disconnect() {
    this.element.removeEventListener("click", this.handleImageClick)
    document.removeEventListener("keydown", this.handleKeydown)
    if (this.modal) this.modal.remove()
  }

  handleImageClick(event) {
    const img = event.target.closest("article img")
    if (!img || !this.element.contains(img) || !this.lightboxEnabledFor(img)) return

    this.openLightbox(img, event)
  }

  openLightbox(img, event) {
    event.preventDefault()

    if (!this.modal) this.createModal()

    const gallery = img.closest(".attachment-gallery")
    if (gallery) {
      this.galleryImages = Array.from(gallery.querySelectorAll("img"))
      this.galleryIndex = this.galleryImages.indexOf(img)
      this.modal.classList.add("lightbox--gallery")
    } else {
      this.galleryImages = null
      this.galleryIndex = -1
      this.modal.classList.remove("lightbox--gallery")
    }

    this.showImage(img)
    document.body.style.overflow = "hidden"

    requestAnimationFrame(() => {
      this.modal.classList.add("show")
    })

    document.addEventListener("keydown", this.handleKeydown)
  }

  showImage(imgOrIndex) {
    const img = typeof imgOrIndex === "number" ? this.galleryImages[imgOrIndex] : imgOrIndex
    const src = img.dataset.lightboxFullUrl || img.src

    if (this.lightboxImage.src === src) return

    // Hide image until loaded to prevent flash of previous image
    this.lightboxImage.style.opacity = "0"
    this.lightboxImage.src = src
    this.lightboxImage.alt = img.alt || ""

    this.lightboxImage.addEventListener("load", () => {
      this.lightboxImage.style.opacity = "1"
    }, { once: true })
  }

  stepGallery(direction) {
    if (!this.galleryImages) return
    this.galleryIndex = (this.galleryIndex + direction + this.galleryImages.length) % this.galleryImages.length
    this.showImage(this.galleryIndex)
  }

  closeLightbox() {
    if (this.modal) {
      this.modal.classList.remove("show")
      document.body.style.overflow = ""
    }

    document.removeEventListener("keydown", this.handleKeydown)
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.closeLightbox()
    } else if (event.key === "ArrowLeft") {
      this.stepGallery(-1)
    } else if (event.key === "ArrowRight") {
      this.stepGallery(1)
    }
  }

  handleBackdropClick(event) {
    if (!event.target.closest("button")) {
      this.closeLightbox()
    }
  }

  handleTouchStart(event) {
    this.touchStartX = event.changedTouches[0].screenX
  }

  handleTouchEnd(event) {
    if (this.touchStartX == null || !this.galleryImages) return

    const delta = event.changedTouches[0].screenX - this.touchStartX
    this.touchStartX = null

    if (Math.abs(delta) < 50) return

    if (delta < 0) {
      this.stepGallery(1)
    } else {
      this.stepGallery(-1)
    }
  }

  createModal() {
    const modal = document.createElement("div")
    modal.className = "lightbox"
    modal.addEventListener("click", this.handleBackdropClick.bind(this))
    modal.addEventListener("touchstart", this.handleTouchStart.bind(this), { passive: true })
    modal.addEventListener("touchend", this.handleTouchEnd.bind(this), { passive: true })

    const closeButton = document.createElement("button")
    closeButton.className = "lightbox__close btn--icon-round"
    closeButton.innerHTML = `
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <line x1="18" y1="6" x2="6" y2="18"></line>
        <line x1="6" y1="6" x2="18" y2="18"></line>
      </svg>
    `
    closeButton.addEventListener("click", () => this.closeLightbox())

    const prevButton = document.createElement("button")
    prevButton.className = "lightbox__nav lightbox__nav--prev btn--icon-round"
    prevButton.innerHTML = `
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="15 18 9 12 15 6"></polyline>
      </svg>
    `
    prevButton.addEventListener("click", () => this.stepGallery(-1))

    const nextButton = document.createElement("button")
    nextButton.className = "lightbox__nav lightbox__nav--next btn--icon-round"
    nextButton.innerHTML = `
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="9 6 15 12 9 18"></polyline>
      </svg>
    `
    nextButton.addEventListener("click", () => this.stepGallery(1))

    const contentWrapper = document.createElement("div")
    contentWrapper.className = "lightbox__content"

    const image = document.createElement("img")

    contentWrapper.appendChild(image)
    modal.appendChild(closeButton)
    modal.appendChild(prevButton)
    modal.appendChild(nextButton)
    modal.appendChild(contentWrapper)
    document.body.appendChild(modal)

    this.modal = modal
    this.lightboxImage = image
  }
}
