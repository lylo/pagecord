import "@hotwired/turbo-rails"
import "controllers"

import "lexxy"
import "@rails/actiontext"

import LocalTime from "local-time"

LocalTime.start()
document.addEventListener("turbo:morph", () => {
  LocalTime.run()
})
