import { Controller } from "@hotwired/stimulus"
import Spotify from "spotify"
import YouTube from "youtube"

// Connects to data-controller="media-embed"
export default class extends Controller {
  connect() {
    this.mediaSites = [new Spotify(), new YouTube()]
    this.replaceMediaLinks()
  }

  replaceMediaLinks() {
    const articles = document.querySelectorAll('article')

    articles.forEach(article => {
      this.mediaSites.forEach(site => {
        this.embedMediaLinks(article, site)
      })
    })
  }

  embedMediaLinks(article, site) {
    const links = Array.from(article.querySelectorAll('a')).filter(link => site.regex.test(link.href))

    links.forEach(link => {
      const url = link.getAttribute("href")
      const linkText = link.textContent.trim()

      if (url === linkText) {
        const embedUrl = site.getEmbedUrl(url)
        if (embedUrl) {
          const iframe = site.createEmbedIframe(embedUrl)
          link.replaceWith(iframe)
        }
      }
    })
  }

}