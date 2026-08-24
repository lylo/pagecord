import * as Lexxy from "lexxy"

const {
  ElementNode,
  TextNode,
  $applyNodeReplacement,
  $createParagraphNode,
  $getRoot,
  $isDecoratorNode,
  $isElementNode,
  $isParagraphNode
} = Lexxy.Lexical

// Footnotes are stored as a marker beside the text and a list at the end:
//
//   <p>Text<sup data-footnote-ref="1" id="fnref-1"><a href="#fn-1">1</a></sup>.</p>
//   <ol data-footnotes>
//     <li id="fn-1"><p>The note text.</p></li>
//   </ol>
//
// which is what Post::Markdown emits for the "[^1]" syntax. Lexical only keeps
// elements it has a node for, so without these three classes it unwraps the <sup>
// down to a bare number and flattens the list, losing the footnotes for good the
// next time the post is saved.
//
// The number is the only thing tying a marker to its note, so it doubles as the
// pairing key: $reconcileFootnotes reads the old numbers to match the two up, then
// rewrites both from the markers' document order.

// The number is generated rather than typed, so a marker wants to behave as one
// atomic thing. A TextNode in "token" mode is selected and deleted whole, which
// gives that, while staying real text in the DOM: a decorator here left the caret
// with nowhere to render when it sat next to the marker, making it near impossible
// to type after one. Subclassing TextNode follows the gem's CodeHighlightNode.
//
// The text *is* the number, so there is no second copy of it to keep in step.
export class FootnoteRefNode extends TextNode {
  static getType() {
    return "footnote-ref"
  }

  // Text, format and mode all come across in TextNode's own afterCloneFrom.
  static clone(node) {
    return new FootnoteRefNode(node.__text, node.__key)
  }

  // Lexical's own TextNode claims <sup> at priority 0 to carry the superscript
  // format, so a footnote marker has to outbid it. Declining a plain <sup> leaves
  // ordinary superscript text alone.
  static importDOM() {
    return {
      sup: (element) => element.hasAttribute("data-footnote-ref") ? { conversion: convertFootnoteRefElement, priority: 1 } : null
    }
  }

  // TextNode serialises its own text, which is all the state there is.
  static importJSON(serializedNode) {
    return $createFootnoteRefNode(1).updateFromJSON(serializedNode)
  }

  // As the gem's CodeHighlightNode does: bold swept across a selection would
  // otherwise write format bits onto the marker that createDOM never renders.
  canHaveFormat() {
    return false
  }

  // Built rather than taken from super, which would give a <span> inside the <sup>.
  // Same shape though, an outer tag wrapping an inner element that holds the text,
  // which is what Lexical's own TextNode.createDOM produces and expects.
  createDOM() {
    const element = document.createElement("sup")
    element.setAttribute("data-footnote-ref", this.__text)
    element.appendChild(this.#anchor())
    return element
  }

  updateDOM(prevNode, element) {
    if (prevNode.__text !== this.__text) {
      element.setAttribute("data-footnote-ref", this.__text)
      element.replaceChildren(this.#anchor())
    }

    return false
  }

  // The editor gets the same anchor as the published post, minus the href: Lexxy
  // styles links with a bare `a` selector rather than a class, so being an anchor is
  // the only way to look exactly like one, and without an href it is styling alone
  // rather than a navigation target the author keeps hitting.
  exportDOM() {
    const element = this.createDOM()
    element.id = `fnref-${this.__text}`
    element.firstChild.href = `#fn-${this.__text}`

    return { element }
  }

  getNumber() {
    return parseInt(this.getTextContent(), 10)
  }

  setNumber(number) {
    if (this.getNumber() !== number) this.setTextContent(String(number))
    return this
  }

  #anchor() {
    const anchor = document.createElement("a")
    anchor.textContent = this.__text
    return anchor
  }
}

// Deliberately not a ListNode subclass. Nothing here wants list types, Tab to
// indent or a start offset, and a plain <ol> numbers its items in the browser
// anyway, so the rendered numbers need no CSS counter.
export class FootnotesNode extends ElementNode {
  static getType() {
    return "footnotes"
  }

  static clone(node) {
    return new FootnotesNode(node.__key)
  }

  static importDOM() {
    return {
      ol: (element) => element.hasAttribute("data-footnotes") ? { conversion: convertFootnotesElement, priority: 1 } : null
    }
  }

  static importJSON(serializedNode) {
    return $createFootnotesNode().updateFromJSON(serializedNode)
  }

  // A boundary, like the callout, so a list or table inserted in a note operates
  // inside the note instead of consuming the whole footnote list.
  isShadowRoot() {
    return true
  }

  // exportDOM is inherited: Lexical builds the exported element from createDOM,
  // so this covers the editor and the saved HTML alike.
  createDOM() {
    const element = document.createElement("ol")
    element.setAttribute("data-footnotes", "")
    return element
  }

  updateDOM() {
    return false
  }
}

export class FootnoteItemNode extends ElementNode {
  __number

  static getType() {
    return "footnote-item"
  }

  static clone(node) {
    return new FootnoteItemNode(node.__number, node.__key)
  }

  // A boundary too, and this one matters for more than insertions: block commands
  // climb to the nearest root or shadow root before acting, so without it a list
  // or quote applied inside a note replaced the note itself, taking its number and
  // therefore its marker with it. With it they act on the paragraph inside, and
  // $enforceFootnoteShape turns that straight back into a paragraph.
  isShadowRoot() {
    return true
  }

  // Only an <li> of a footnote list is a note; every other list item keeps
  // Lexical's own handling.
  static importDOM() {
    return {
      li: (element) => element.parentElement?.hasAttribute("data-footnotes") ? { conversion: convertFootnoteItemElement, priority: 1 } : null
    }
  }

  static importJSON(serializedNode) {
    return $createFootnoteItemNode(serializedNode.number).updateFromJSON(serializedNode)
  }

  constructor(number = 1, key) {
    super(key)
    this.__number = number
  }

  createDOM() {
    const element = document.createElement("li")
    element.id = `fn-${this.__number}`
    return element
  }

  updateDOM(prevNode, element) {
    if (prevNode.__number !== this.__number) {
      element.id = `fn-${this.__number}`
    }

    return false
  }

  exportJSON() {
    return { ...super.exportJSON(), number: this.getNumber() }
  }

  getNumber() {
    return this.getLatest().__number
  }

  setNumber(number) {
    if (this.getNumber() !== number) this.getWritable().__number = number
    return this
  }
}

// forChild drops the children: the anchor inside a stored marker is presentation
// that exportDOM rebuilds, and importing it would leave a link node in the model.
function convertFootnoteRefElement(element) {
  return {
    node: $createFootnoteRefNode(footnoteNumber(element.getAttribute("data-footnote-ref"))),
    forChild: () => null
  }
}

function convertFootnotesElement() {
  return { node: $createFootnotesNode() }
}

function convertFootnoteItemElement(element) {
  return { node: $createFootnoteItemNode(footnoteNumber(element.id.replace(/^fn-/, ""))) }
}

// Markdown always numbers from one, but hand-written HTML might not, and a marker
// with no usable number would pair with nothing. Reconciling renumbers everything
// from document order regardless, so any placeholder survives one pass.
function footnoteNumber(value) {
  return parseInt(value, 10) || 1
}

// Token mode is what makes the marker atomic: the caret goes either side of it but
// never inside, and backspace takes the whole thing.
export function $createFootnoteRefNode(number) {
  return $applyNodeReplacement(new FootnoteRefNode(String(number))).setMode("token")
}

export function $createFootnotesNode() {
  return $applyNodeReplacement(new FootnotesNode())
}

export function $createFootnoteItemNode(number) {
  return $applyNodeReplacement(new FootnoteItemNode(number))
}

export function $isFootnoteRefNode(node) {
  return node instanceof FootnoteRefNode
}

export function $isFootnotesNode(node) {
  return node instanceof FootnotesNode
}

export function $isFootnoteItemNode(node) {
  return node instanceof FootnoteItemNode
}

export function $footnotesList() {
  return $getRoot().getChildren().find($isFootnotesNode)
}

// Markers in document order, which is the order the numbering follows. Notes are
// skipped: a marker inside a note would number itself out of the reading order.
export function $footnoteRefs(node = $getRoot(), refs = []) {
  for (const child of node.getChildren()) {
    if ($isFootnoteRefNode(child)) {
      refs.push(child)
    } else if ($isElementNode(child) && !$isFootnotesNode(child)) {
      $footnoteRefs(child, refs)
    }
  }

  return refs
}

export function $appendFootnotesList() {
  const list = $createFootnotesNode()
  $getRoot().append(list)
  return list
}

// A note holds inline content in paragraphs and nothing else. Block elements that
// land in one are folded back into paragraphs keeping their inline content, so
// lists, quotes and headings, which know nothing about footnotes, read as no-ops
// rather than restructuring the note. Decorators, which have no inline content to
// keep, are removed: attachments and dividers arrive by toolbar, paste or drag, and
// this one transform covers every route in. A marker inside a note goes the same
// way, since it would sit where $footnoteRefs deliberately never looks and could
// never be numbered. Registered as a node transform by the extension, as callouts do.
export function $enforceFootnoteShape(item) {
  for (const child of item.getChildren()) {
    if ($isElementNode(child) && !child.isInline() && !$isParagraphNode(child)) {
      child.replace($createParagraphNode().append(...$inlineContent(child)))
    }
  }

  $removeDisallowedContent(item)
}

function $inlineContent(node) {
  if (!$isElementNode(node) || node.isInline()) return [ node ]

  return node.getChildren().flatMap((child) => $inlineContent(child))
}

function $removeDisallowedContent(node) {
  for (const child of node.getChildren()) {
    if ($isDecoratorNode(child) || $isFootnoteRefNode(child)) {
      child.remove()
    } else if ($isElementNode(child)) {
      $removeDisallowedContent(child)
    }
  }
}

// Everything the author can do to a footnote reduces to this one pass, which is
// why there is no per-operation bookkeeping: inserting, deleting or moving a
// marker, or pasting a paragraph full of them, all just change the marker order.
//
// It must stay idempotent. It runs after every update that touches a footnote, so
// a pass that dirtied nodes when nothing had moved would re-trigger itself
// forever. Both setNumber calls no-op on an unchanged number, and the notes are
// only reordered when the order is actually wrong.
export function $reconcileFootnotes() {
  const list = $footnotesList()
  if (!list) return

  const items = new Map(list.getChildren().filter($isFootnoteItemNode).map((item) => [ item.getNumber(), item ]))

  // Pair on the numbers as they stand, before either side is rewritten. The pairing
  // is many-to-one: markdown lets several references share one definition, and
  // copy-pasting a marker makes the same shape, so notes take the order of their
  // first marker and every marker of a note carries that note's number. A marker
  // whose note has been deleted goes too, so deleting either half of a footnote
  // takes the other with it.
  const paired = []
  const notes = []
  for (const ref of $footnoteRefs()) {
    const item = items.get(ref.getNumber())
    if (!item) { ref.remove(); continue }

    if (!notes.includes(item)) notes.push(item)
    paired.push([ ref, item ])
  }

  if (notes.length === 0) return list.remove()

  // Keys rather than object identity: a node is a different object once written.
  // Only notes are dropped, so anything else that ends up in the list survives
  // rather than being silently deleted along with whatever the author put there.
  const kept = new Set(notes.map((item) => item.getKey()))
  list.getChildren().forEach((child) => {
    if ($isFootnoteItemNode(child) && !kept.has(child.getKey())) child.remove()
  })

  const current = list.getChildren().filter($isFootnoteItemNode)
  if (!sameOrder(current, notes)) notes.forEach((item) => list.append(item))

  notes.forEach((item, index) => item.setNumber(index + 1))
  paired.forEach(([ ref, item ]) => ref.setNumber(item.getNumber()))
}

function sameOrder(current, expected) {
  return current.length === expected.length && current.every((node, index) => node.is(expected[index]))
}

// A new marker and its note are created as a pair sharing a number no existing
// footnote uses, so reconciling matches them up and moves the note into place.
export function $insertFootnote(selection) {
  const list = $footnotesList() ?? $appendFootnotesList()
  const number = nextNumber(list)
  const item = $createFootnoteItemNode(number)

  item.append($createParagraphNode())
  list.append(item)
  $collapseToEnd(selection)
  selection.insertNodes([ $createFootnoteRefNode(number) ])

  return item
}

// insertNodes replaces whatever is selected, so footnoting a selected word would
// delete the word. A marker belongs after the thing it annotates, and collapsing to
// the end of the selection both puts it there and drops the selection.
function $collapseToEnd(selection) {
  if (selection.isCollapsed()) return

  const end = selection.isBackward() ? selection.anchor : selection.focus
  selection.anchor.set(end.key, end.offset, end.type)
  selection.focus.set(end.key, end.offset, end.type)
}

function nextNumber(list) {
  const numbers = list.getChildren().filter($isFootnoteItemNode).map((item) => item.getNumber())
  return numbers.length > 0 ? Math.max(...numbers) + 1 : 1
}
