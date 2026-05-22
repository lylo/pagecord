import MediaSite from "media_site"

class Strava extends MediaSite {
  constructor() {
    super(
      /https:\/\/www\.strava\.com\/activities\/([0-9]+)(?:\/.*)?/,

      async (url) => {
        const match = url.match(this.regex)
        if (match) {
          const id = match[1]
          return id;
        }
        return null
      },

      (id) => {
        const wrapper = document.createElement("div")
        wrapper.style.display = "flex"
        wrapper.style.justifyContent = "center"

        const div = document.createElement("div")
        div.className = "strava-embed-placeholder"
        div.dataset.embedType = "activity"
        div.dataset.embedId = id
        div.dataset.style = "standard"
        div.dataset.fromEmbed = "false"

        const script = document.createElement('script')
        script.src = "https://strava-embeds.com/embed.js"

        wrapper.appendChild(div)
        wrapper.appendChild(script)
        return wrapper
      }
    )
  }
}

export default Strava