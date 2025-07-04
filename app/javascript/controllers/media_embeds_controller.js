import { Controller } from "@hotwired/stimulus"
import AppleMusic from "apple_music"
import Bandcamp from "bandcamp"
import Checkvist from "checkvist"
import GitHub from "github"
import Image from "image"
import Spotify from "spotify"
import Strava from "strava"
import Transistor from "transistor"
import YouTube from "youtube"

// Connects to data-controller="media-embed"
export default class extends Controller {
  connect() {
    this.mediaSites = [new AppleMusic(), new Spotify(), new YouTube(), new Bandcamp(), new Strava(), new GitHub(), new Image(), new Transistor(), new Checkvist()]
    this.replaceMediaLinks()
  }

  async replaceMediaLinks() {
    const articles = document.querySelectorAll('article')

    for (const article of articles) {
      const links = Array.from(article.querySelectorAll('a'))
        .filter(link => link.href === link.textContent.trim())

      await Promise.all(links.map(link => this.processLink(link)))
    }
  }

  async processLink(link) {
    const url = link.href

    for (const site of this.mediaSites) {
      if (site.regex.test(url)) {
        const iframe = await site.transform(url)
        if (iframe) {
          link.replaceWith(iframe)
          break // Stop after first successful match
        }
      }
    }
  }
}