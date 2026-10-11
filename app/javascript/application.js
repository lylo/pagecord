import "@hotwired/turbo-rails"
import "controllers"


import * as Lexxy from "lexxy"
import CalloutExtension from "editor/callout_extension"
import EmbedExtension from "editor/embed_extension"
import FootnoteExtension from "editor/footnote_extension"
import ToolbarOrderExtension from "editor/toolbar_order_extension"
import UnfurlExtension from "editor/unfurl_extension"
import "@rails/actiontext"

// ToolbarOrderExtension last: it rearranges the buttons the others have added.
Lexxy.configure({ global: { extensions: [ CalloutExtension, EmbedExtension, UnfurlExtension, FootnoteExtension, ToolbarOrderExtension ] } })

import LocalTime from "local-time"

LocalTime.start()
