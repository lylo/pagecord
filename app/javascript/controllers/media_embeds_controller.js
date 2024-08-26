import { Controller } from "@hotwired/stimulus";
import Spotify from '../embeds/spotify';
import YouTube from '../embeds/youtube';

// Connects to data-controller="media-embed"
export default class extends Controller {
  connect() {
    this.mediaSites = [new Spotify(), new YouTube()];
    this.replaceMediaLinksAndText();
  }

  replaceMediaLinksAndText() {
    const articles = document.querySelectorAll('article');

    articles.forEach(article => {
      this.mediaSites.forEach(site => {
        this.embedMediaLinks(article, site);
        this.embedPlainTextLinks(article, site);
      });
    });
  }

  embedMediaLinks(article, site) {
    const links = Array.from(article.querySelectorAll('a')).filter(link => site.regex.test(link.href));
    links.forEach(link => {
      const url = link.getAttribute("href");
      const linkText = link.textContent.trim();

      if (url === linkText) {
        const embedUrl = site.getEmbedUrl(url);
        if (embedUrl) {
          const iframe = site.createEmbedIframe(embedUrl);
          link.replaceWith(iframe);
        }
      }
    });
  }

  embedPlainTextLinks(article, site) {
    const walker = document.createTreeWalker(article, NodeFilter.SHOW_TEXT, null, false);
    let node;

    while (node = walker.nextNode()) {
      const text = node.nodeValue;
      const match = text.match(site.regex);

      if (match) {
        const url = match[0];
        const embedUrl = site.getEmbedUrl(url);

        if (embedUrl) {
          const iframe = site.createEmbedIframe(embedUrl);
          const span = document.createElement('span');
          span.appendChild(iframe);

          const parts = text.split(url);
          node.nodeValue = parts[0];
          node.parentNode.insertBefore(span, node.nextSibling);

          if (parts[1]) {
            const remainder = document.createTextNode(parts[1]);
            node.parentNode.insertBefore(remainder, span.nextSibling);
          }
        }
      }
    }
  }
}