# Import map for public blog pages. Kept separate from config/importmap.rb so
# app-only modules (editor, CodeMirror, uploads) never appear in blog HTML.

pin "blog", preload: true

pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "local-time"
pin "lexxy", to: "lexxy.min.js", preload: false

# Controllers used by blog views - lazy loaded
pin "controllers/fade_controller", preload: false
pin "controllers/lightbox_controller", preload: false
pin "controllers/media_embeds_controller", preload: false
pin "controllers/pv_controller", preload: false
pin "controllers/syntax_highlight_controller", preload: false
pin "controllers/turbo_frame_top_controller", preload: false
pin "controllers/upvote_controller", preload: false

# Media embed handlers - lazy loaded
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
