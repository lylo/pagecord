# Pin npm packages by running ./bin/importmap

# Entry points - each preloads only for itself
pin "application", preload: "application"
pin "blog", preload: "blog"
pin "home", preload: "home"

# Core dependencies - always preloaded
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# Controllers - lazy loaded, no preload needed
pin_all_from "app/javascript/controllers", under: "controllers", preload: false

# App-only dependencies (editor, file uploads, etc.)
pin "lexxy", to: "lexxy.min.js", preload: "application"
pin "@rails/actiontext", to: "actiontext.esm.js", preload: "application"
pin "@rails/activestorage", to: "activestorage.esm.js", preload: "application"
pin "local-time", preload: "application"
pin "@yaireo/tagify", to: "@yaireo--tagify.js", preload: "application"
pin "sortablejs", to: "sortablejs.js", preload: "application"
pin "@rails/request.js", to: "@rails--request.js", preload: "application"
pin "stimulus-sortable", to: "stimulus-sortable.js", preload: "application"

# CodeMirror 5 for CSS editing (app only)
pin "codemirror", to: "codemirror/codemirror.js", preload: "application"
pin "codemirror/mode/css/css", to: "codemirror/css.js", preload: "application"
pin "codemirror/addon/edit/matchbrackets", to: "codemirror/matchbrackets.js", preload: "application"
pin "codemirror/addon/edit/closebrackets", to: "codemirror/closebrackets.js", preload: "application"
pin "codemirror/addon/hint/show-hint", to: "codemirror/show-hint.js", preload: "application"
pin "codemirror/addon/hint/css-hint", to: "codemirror/css-hint.js", preload: "application"

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
