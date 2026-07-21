import MediaSite from "media_site"

class YouTube extends MediaSite {
  constructor() {
    super(
      /(?:https:\/\/(?:www\.|music\.)?youtube\.com\/(?:watch\?v=|live\/|shorts\/|playlist\?list=)|https:\/\/youtu\.be\/)([a-zA-Z0-9_-]+)/,

      async (url) => {
        const list = new URL(url).searchParams.get("list")
        if (list) {
          return `https://www.youtube-nocookie.com/embed?listType=playlist&list=${list}`
        }

        const match = url.match(this.regex)
        if (match) {
          return `https://www.youtube-nocookie.com/embed/${match[1]}`
        }
        return null
      },

      (embedUrl) => {
        const div = document.createElement('div')
        div.className = "video-embed-container"

        const iframe = document.createElement('iframe')
        iframe.src = embedUrl
        iframe.loading = "lazy"
        iframe.allow = "autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture"

        div.appendChild(iframe)

        return div
      }
    )
  }
}

export default YouTube
