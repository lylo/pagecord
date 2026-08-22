import "@hotwired/turbo-rails"
import "controllers"


import * as Lexxy from "lexxy"
import CalloutExtension from "editor/callout_extension"
import "@rails/actiontext"

Lexxy.configure({ global: { extensions: [ CalloutExtension ] } })

import LocalTime from "local-time"

LocalTime.start()
document.addEventListener("turbo:morph", () => {
  LocalTime.run()
})
