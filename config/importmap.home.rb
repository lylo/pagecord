# Import map for the marketing pages (home layout): Stimulus and the letter controllers only.
# A Stimulus controller used on a marketing page must be pinned here too, or it won't load.

pin "home", preload: true

pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin "controllers/signup_letter_controller", preload: false
pin "controllers/signature_controller", preload: false
