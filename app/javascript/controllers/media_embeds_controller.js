import { Controller } from "@hotwired/stimulus"
import Bandcamp from "bandcamp"
import Spotify from "spotify"
import YouTube from "youtube"

// Connects to data-controller="media-embed"
export default class extends Controller {
  connect() {
    this.mediaSites = [new Spotify(), new YouTube(), new Bandcamp()]
    this.replaceMediaLinks()
  }

  async replaceMediaLinks() {
    const articles = document.querySelectorAll('article')

    for (const article of articles) {
      for (const site of this.mediaSites) {
        await this.embedMediaLinks(article, site)
      }
    }
  }

  async embedMediaLinks(article, site) {
    const links = Array.from(article.querySelectorAll('a')).filter(link => site.regex.test(link.href))

    for (const link of links) {
      const url = link.getAttribute("href")
      const linkText = link.textContent.trim()

      if (url === linkText) {
        const iframe = await site.transform(url)
        if (iframe) {
          link.replaceWith(iframe)
        }
      }
    }
  }
}