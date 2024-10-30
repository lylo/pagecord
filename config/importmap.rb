# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"
pin "bandcamp", to: "embeds/bandcamp.js"
pin "spotify", to: "embeds/spotify.js"
pin "youtube", to: "embeds/youtube.js"
pin "media_site", to: "embeds/media_site.js"
