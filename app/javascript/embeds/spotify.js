import MediaSite from "media_site"

class Spotify extends MediaSite {
  constructor() {
    super(
      /https:\/\/open\.spotify\.com\/(track|album|playlist|episode|show)\/([a-zA-Z0-9]+)(\?.*)?/,

      async (url) => {
        const match = url.match(this.regex)
        if (match) {
          const type = match[1]
          const id = match[2]
          return `https://open.spotify.com/embed/${type}/${id}`
        }
        return null
      },

      (embedUrl) => {
        const iframe = document.createElement('iframe')
        iframe.src = `${embedUrl}?utm_source=generator&theme=0`
        iframe.width = "100%"
        iframe.height = "152"
        iframe.allow = "autoplay clipboard-write encrypted-media encrypted-media fullscreen picture-in-picture"
        iframe.loading = "lazy"
        iframe.style.borderRadius = "12px"
        return iframe
      }
    )
  }
}

export default Spotify