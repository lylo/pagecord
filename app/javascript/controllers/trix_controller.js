import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("trix-initialize", (event) => {
      const editor = event.target
      const subscribed = editor.dataset.subscribed

      if (!subscribed) {
        editor.addEventListener("trix-file-accept", (e) => {
          e.preventDefault()
          alert("Attachments are only available for paying customers")
        })
      }
   })
  }
}