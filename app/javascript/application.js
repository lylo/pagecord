import "@hotwired/turbo-rails"
import "controllers"


import "lexxy"
import "@rails/actiontext"

import LocalTime from "local-time"

LocalTime.start()
document.addEventListener("turbo:morph", () => {
  LocalTime.run()
})

// iOS PWAs can freeze the JS context when the app is backgrounded.
// When resumed, Turbo may think a visit/submission is still in progress,
// causing buttons and links to silently stop working. Cancel any stuck
// visit so Turbo accepts new interactions again.
document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "visible") {
    window.Turbo?.navigator?.currentVisit?.cancel()
  }
})
