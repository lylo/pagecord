import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.inputTarget.addEventListener('input', this.handleFileSelect.bind(this));
  }

  disconnect() {
    this.inputTarget.removeEventListener('input', this.handleFileSelect.bind(this));
  }

  open(event) {
    this.inputTarget.click()
    event.preventDefault()
  }

  handleFileSelect(event) {
    const file = event.target.files[0];
    if (file) {
      const allowedTypes = ['image/jpeg', 'image/png', 'image/webp']
      const fileType = file.type

      if (allowedTypes.includes(fileType)) {
        const reader = new FileReader()

        reader.onload = function (e) {
          const imageUrl = e.target.result

          const container = document.getElementById("blog-avatar")
          if (!container) {
            throw new Error('No container found')
          }
          const avatarImage = container.querySelector("img")
          if (avatarImage) {
            avatarImage.src = imageUrl
            const placeholder = container.querySelector(".avatar-placeholder")
            if(placeholder) {
              if (avatarImage.classList.contains("hidden")) {
                avatarImage.classList.remove("hidden")
              }

              if(!placeholder.classList.contains("hidden")) {
                placeholder.classList.add("hidden")
              }
            }
          }
        }

        reader.readAsDataURL(file)
      } else {
        alert("Please select a valid image")
      }
    }
  }
}
