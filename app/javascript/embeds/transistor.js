import MediaSite from "media_site"

class Transistor extends MediaSite {
  constructor() {
    super(
      /https:\/\/share\.transistor\.fm\/[se]\/([a-zA-Z0-9\-]+)(?:\/(latest|playlist|[a-zA-Z0-9\-]+))?\??(.*)$/,

      async (url) => {
        const match = url.match(this.regex)
        if (match) {
          const showSlug = match[1]
          const episodeOrType = match[2] || ''

          if (episodeOrType) {
            return `https://share.transistor.fm/e/${showSlug}/${episodeOrType}`
          } else {
            return `https://share.transistor.fm/e/${showSlug}`
          }
        }
        return null
      },

      (embedUrl) => {
        const iframe = document.createElement('iframe')
        iframe.src = `${embedUrl}?color=444444&background=ffffff`
        iframe.width = "100%"
        iframe.style.border = "none"
        iframe.seamless = true
        iframe.loading = "lazy"

        if (embedUrl.includes('/playlist')) {
          iframe.height = "390"
        } else {
          iframe.height = "180"
        }

        return iframe
      }
    )
  }
}

export default Transistor
