import { Controller } from "@hotwired/stimulus"

// Transitional: nothing rendered since the frames gained target="_top"
// references this controller, but blog pages are edge-cached for 12 hours and
// the cached HTML still asks for it. Without it, links inside post bodies on
// stale pages would target the frame and dead-click. Delete once the cache
// has turned over.
export default class extends Controller {
  connect() {
    this.element.querySelectorAll('a').forEach(link => {
      if (!link.dataset.turboFrame) {
        link.dataset.turboFrame = "_top"
      }
    })
  }
}
