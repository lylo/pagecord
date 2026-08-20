import "@hotwired/turbo-rails"
import "controllers"


import * as Lexxy from "lexxy"
import CalloutExtension from "editor/callout_extension"
import FootnoteExtension from "editor/footnote_extension"
import ToolbarOrderExtension from "editor/toolbar_order_extension"
import "@rails/actiontext"

// ToolbarOrderExtension last: it rearranges the buttons the others have added.
Lexxy.configure({ global: { extensions: [ CalloutExtension, FootnoteExtension, ToolbarOrderExtension ] } })

import LocalTime from "local-time"

LocalTime.start()
document.addEventListener("turbo:morph", () => {
  LocalTime.run()
})
