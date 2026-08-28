import { Controller } from "@hotwired/stimulus"
import { isEmbeddableLink, mediaSites } from "media_sites"

export default class extends Controller {
  connect() {
    this.mediaSites = mediaSites()
    this.replaceMediaLinks()
  }

  async replaceMediaLinks() {
    const articles = Array.from(this.element.querySelectorAll('article'))
    const links = articles.flatMap(a => Array.from(a.querySelectorAll('a')).filter(l => isEmbeddableLink(l, this.mediaSites)))
    await Promise.all(links.map(link => this.processLink(link)))
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
