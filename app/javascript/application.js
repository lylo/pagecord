import "@hotwired/turbo-rails"
import "controllers"


import * as Lexxy from "lexxy"
Lexxy.configure({ default: { toolbar: { upload: "image" } } })
import "@rails/actiontext"

import LocalTime from "local-time"

LocalTime.start()
document.addEventListener("turbo:morph", () => {
  LocalTime.run()
})
