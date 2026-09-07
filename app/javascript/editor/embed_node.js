import * as Lexxy from "lexxy"
import { editorMediaSites, isAloneInItsBlock, isBareLink, isSameTarget, matchingSite } from "media_sites"

const { DecoratorNode, $createParagraphNode, $applyNodeReplacement } = Lexxy.Lexical

const SITES = editorMediaSites()

// An embed is stored as the bare link the author pasted:
//
//   <p><a href="https://open.spotify.com/album/53Rf">https://open.spotify.com/album/53Rf</a></p>
//
// which is what media_embeds_controller swaps for an iframe when the post is read.
// This node shows the same iframe while writing without changing any of that:
// createDOM builds the player, exportDOM hands the paragraph and link straight
// back, so a post round-trips through the editor unchanged. Storing the iframe
// instead would freeze every post at today's embed URL format, where a provider
// changing theirs is currently a one-line fix to the regex in embeds/.
//
// A DecoratorNode whose decorate() returns null is how Lexxy's own attachment node
// does this: the visible DOM comes from createDOM, leaving exportDOM free to differ.
export class EmbedNode extends DecoratorNode {
  __url

  static getType() {
    return "media-embed"
  }

  static clone(node) {
    return new EmbedNode(node.__url, node.__key)
  }

  // Opening a post is an HTML parse, where there is no selection to look after and
  // the conversion can simply claim the link. Lexical's own link node claims every
  // <a> at priority 1, so a bare link to a provider has to outbid it; declining
  // everything else leaves ordinary links exactly as they were.
  //
  // isAloneInItsBlock rather than the blog's own-line rule: this node is a block,
  // and claiming a link that shares its block with anything makes Lexical split
  // the block around it, silently rewriting the post on the next save.
  static importDOM() {
    return {
      a: (element) => isEmbeddableElement(element) ? { conversion: convertEmbedElement, priority: 3 } : null
    }
  }

  static importJSON(serializedNode) {
    return $createEmbedNode(serializedNode.url).updateFromJSON(serializedNode)
  }

  constructor(url, key) {
    super(key)
    this.__url = url
  }

  isInline() {
    return false
  }

  createDOM() {
    const element = document.createElement("div")
    element.className = "media-embed"
    this.#renderInto(element)
    return element
  }

  // The URL is the whole of the state, and a node is created per URL rather than
  // retargeted, so there is never anything to update.
  updateDOM() {
    return false
  }

  exportDOM() {
    const paragraph = document.createElement("p")
    paragraph.appendChild(linkTo(this.__url))

    return { element: paragraph }
  }

  exportJSON() {
    return { ...super.exportJSON(), url: this.__url }
  }

  decorate() {
    return null
  }

  // Bandcamp and Bluesky resolve their embed URL over the network, so the link
  // stands in until the provider answers, and stays put if it never does.
  async #renderInto(element) {
    element.appendChild(linkTo(this.__url))

    const embed = await matchingSite(this.__url, SITES)?.transform(this.__url)
    if (embed) element.replaceChildren(embed)
  }
}

function linkTo(url) {
  const link = document.createElement("a")
  link.setAttribute("href", url)
  link.textContent = url

  return link
}

export function $createEmbedNode(url) {
  return $applyNodeReplacement(new EmbedNode(url))
}

export function $isEmbedNode(node) {
  return node instanceof EmbedNode
}

// Pasting is the other way an embed appears, and it takes a different route: there
// is no HTML to parse, just a link node arriving in a live document, so importDOM
// never runs. The paragraph transform catches that, and is also where the embed
// importDOM built gets lifted out of the paragraph it was parsed inside.
//
// The paragraph has to hold the link and nothing else. That is what the help guide
// promises, and it is the only place a player fits: a URL with prose beside it is a
// sentence, and a block-level iframe would break the line in half.
export function $embedLinkParagraph(paragraph) {
  const children = paragraph.getChildren()
  if (children.length !== 1) return

  const [ child ] = children

  if ($isEmbedNode(child)) {
    paragraph.replace(child)
  } else if (isEmbeddableLinkNode(child)) {
    const embed = $createEmbedNode(child.getURL())
    paragraph.replace(embed)
    $moveCaretAfter(embed)
  }
}

// An embed holds no text, so replacing the paragraph the caret was in leaves the
// selection pointing at a node that no longer exists. Lexical resolves that by
// dropping the selection, and the embed goes with it, so the caret has to be given
// somewhere to land, which at the end of a post means a new paragraph.
export function $moveCaretAfter(embed) {
  const next = embed.getNextSibling()

  if (next) {
    next.selectStart()
  } else {
    const paragraph = $createParagraphNode()
    embed.insertAfter(paragraph)
    paragraph.selectEnd()
  }
}

function isEmbeddableElement(element) {
  return isBareLink(element) && isAloneInItsBlock(element) && matchingSite(element.href, SITES) !== null
}

function convertEmbedElement(element) {
  return { node: $createEmbedNode(element.href) }
}

// The same two questions as isEmbeddableLink, asked of a Lexical node instead of a
// DOM element. A pasted link is already a node, so there is no element to ask.
function isEmbeddableLinkNode(node) {
  return node.getType() === "link" &&
    isSameTarget(node.getURL(), node.getTextContent().trim()) &&
    matchingSite(node.getURL(), SITES) !== null
}
