import MediaSite from "media_site"

class Checkvist extends MediaSite {
  constructor() {
    super(
      /https:\/\/checkvist\.com\/p\/([a-zA-Z0-9]+)/,

      async (url) => {
        const match = url.match(this.regex)
        if (match) {
          return url
        }
        return null
      },

      (embedUrl) => {
        const iframe = document.createElement('iframe')
        iframe.src = embedUrl
        iframe.width = "100%"
        iframe.height = "400"
        return iframe
      }
    )
  }
}

export default Checkvist
