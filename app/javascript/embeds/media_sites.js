import AppleMusic from "apple_music"
import Bandcamp from "bandcamp"
import Bluesky from "bluesky"
import GitHub from "github"
import Image from "image"
import Spotify from "spotify"
import Strava from "strava"
import Tidal from "tidal"
import Transistor from "transistor"
import YouTube from "youtube"

// Match order: the first site whose regex accepts a URL is the one that transforms
// it, so anything with a broad pattern belongs at the end.
const SITES = [ AppleMusic, Spotify, YouTube, Bandcamp, Bluesky, Strava, GitHub, Image, Transistor, Tidal ]

// Strava injects a <script> tag and Image swaps in an <img>. Neither belongs in the
// editor: one runs third-party code while you write, the other is indistinguishable
// from a Lexxy attachment once rendered.
const NOT_IN_EDITOR = [ Strava, Image ]

export function mediaSites() {
  return SITES.map((Site) => new Site())
}

export function editorMediaSites() {
  return SITES.filter((Site) => !NOT_IN_EDITOR.includes(Site)).map((Site) => new Site())
}

export function matchingSite(url, sites) {
  return sites.find((site) => site.regex.test(url)) || null
}

// The two things that make a link an embed, asked in one place so the editor's
// preview and the published post can never disagree about what embeds.
export function isEmbeddableLink(link, sites) {
  return isBareLink(link) && isOnItsOwnLine(link) && matchingSite(link.href, sites) !== null
}

// A link the author wrote as a bare URL: one with its own text was written
// deliberately, and a player would throw that text away.
export function isBareLink(link) {
  return isSameTarget(link.href, link.textContent.trim())
}

// "On its own line", which is what the help guide promises and the only place a
// block-level player fits: a URL with prose beside it is a sentence, and an iframe
// would break the line in half.
//
// The check climbs to the link's block, because the URL may sit inside inline
// wrappers (<em>, <strong>) and prose beside any of them is still prose beside the
// link. Walking each level out to the nearest break rather than comparing the whole
// block's text, because Trix-era posts put several lines in one block separated by
// <br>.
export function isOnItsOwnLine(link) {
  return isAloneOnItsLine(link, (node) => node.nodeName === "BR")
}

// The editor's stricter version: alone in its whole block, <br> lines included. In
// a published page swapping the <a> for a player leaves the rest of the block
// alone, but importing a block node mid-paragraph makes Lexical split the
// paragraph, silently rewriting the post. Those URLs stay links in the editor and
// still embed on the blog.
export function isAloneInItsBlock(link) {
  return isAloneOnItsLine(link, () => false)
}

const INLINE_WRAPPERS = [ "A", "EM", "I", "STRONG", "B", "U", "S", "DEL", "MARK", "SPAN", "CODE" ]

function isAloneOnItsLine(link, boundary) {
  let node = link

  while (INLINE_WRAPPERS.includes(node.nodeName)) {
    if (!emptyBeside(node.previousSibling, "previousSibling", boundary)) return false
    if (!emptyBeside(node.nextSibling, "nextSibling", boundary)) return false
    if (!node.parentElement) return true

    node = node.parentElement
  }

  return true
}

function emptyBeside(node, direction, boundary) {
  while (node) {
    if (boundary(node)) return true
    if (node.textContent.trim() !== "") return false

    node = node[direction]
  }

  return true
}

// The query string is ignored so a URL something has since decorated with tracking
// parameters still reads as bare.
export function isSameTarget(href, text) {
  if (href === text) return true

  try {
    const hrefUrl = new URL(href)
    const textUrl = new URL(text)
    return hrefUrl.origin + hrefUrl.pathname === textUrl.origin + textUrl.pathname
  } catch {
    return false
  }
}
