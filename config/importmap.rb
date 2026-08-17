# Pin npm packages by running ./bin/importmap
#
# This map is inlined in full on every page that uses it, so public blog pages
# draw their own smaller map from config/importmap.blog.rb instead.

# Entry point for the app and admin
pin "application"

# Core dependencies
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# Controllers - lazy loaded, no preload needed
pin_all_from "app/javascript/controllers", under: "controllers", preload: false

# App-only dependencies (editor, file uploads, etc.)
pin "lexxy", to: "lexxy.min.js"
pin "@rails/actiontext", to: "actiontext.esm.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "local-time"
pin "@yaireo/tagify", to: "@yaireo--tagify.js"
pin "sortablejs", to: "sortablejs.js"
pin "@rails/request.js", to: "@rails--request.js"
pin "stimulus-sortable", to: "stimulus-sortable.js"

# CodeMirror 5 for the custom code editors (app only). Lazy: this is a third of
# a megabyte for one settings page, so it must not preload on every app page.
pin "codemirror", to: "codemirror/codemirror.js", preload: false
pin "codemirror/mode/css/css", to: "codemirror/css.js", preload: false
pin "codemirror/mode/xml/xml", to: "codemirror/xml.js", preload: false
pin "codemirror/mode/javascript/javascript", to: "codemirror/javascript.js", preload: false
pin "codemirror/mode/htmlmixed/htmlmixed", to: "codemirror/htmlmixed.js", preload: false
pin "codemirror/addon/edit/matchbrackets", to: "codemirror/matchbrackets.js", preload: false
pin "codemirror/addon/edit/closebrackets", to: "codemirror/closebrackets.js", preload: false
pin "codemirror/addon/edit/closetag", to: "codemirror/closetag.js", preload: false
pin "codemirror/addon/edit/matchtags", to: "codemirror/matchtags.js", preload: false
pin "codemirror/addon/fold/xml-fold", to: "codemirror/xml-fold.js", preload: false
pin "codemirror/addon/hint/show-hint", to: "codemirror/show-hint.js", preload: false
pin "codemirror/addon/hint/css-hint", to: "codemirror/css-hint.js", preload: false

# Media embed handlers - lazy loaded (used by blogs and app)
pin "apple_music", to: "embeds/apple_music.js", preload: false
pin "bluesky", to: "embeds/bluesky.js", preload: false
pin "bandcamp", to: "embeds/bandcamp.js", preload: false
pin "checkvist", to: "embeds/checkvist.js", preload: false
pin "github", to: "embeds/github.js", preload: false
pin "image", to: "embeds/image.js", preload: false
pin "spotify", to: "embeds/spotify.js", preload: false
pin "strava", to: "embeds/strava.js", preload: false
pin "tidal", to: "embeds/tidal.js", preload: false
pin "transistor", to: "embeds/transistor.js", preload: false
pin "youtube", to: "embeds/youtube.js", preload: false
pin "media_site", to: "embeds/media_site.js", preload: false
