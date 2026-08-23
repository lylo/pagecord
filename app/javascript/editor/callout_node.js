import * as Lexxy from "lexxy"

const {
  ElementNode,
  ParagraphNode,
  $applyNodeReplacement,
  $createParagraphNode,
  $createTextNode,
  $isElementNode,
  $isParagraphNode
} = Lexxy.Lexical

// Obsidian's canonical callout types. Its aliases are folded onto these by
// Post::Markdown before anything reaches the editor. https://obsidian.md/help/callouts
const CALLOUT_TYPES = [
  "note", "info", "todo", "abstract", "tip", "success",
  "question", "warning", "failure", "danger", "bug", "example", "quote"
]

// The subset offered in the toolbar, one per colour, to keep the picker compact.
// Every type above still round-trips; these are just the ones worth a swatch.
export const TOOLBAR_CALLOUT_TYPES = [ "note", "tip", "success", "warning", "danger" ]

const DEFAULT_CALLOUT_TYPE = "note"

export function calloutLabel(calloutType) {
  return calloutType.charAt(0).toUpperCase() + calloutType.slice(1)
}

// Callouts are stored as:
//
//   <aside data-callout="note">
//     <p data-callout-title>Heads up</p>
//     <p>Body</p>
//   </aside>
//
// which is what Post::Markdown emits for Obsidian's "> [!note] Heads up" syntax.
// Lexical only keeps elements it has a node for, so without these two classes it
// unwraps the <aside>, lifts the paragraphs, and the callout is gone for good the
// next time the post is saved.
export class CalloutNode extends ElementNode {
  __calloutType

  static getType() {
    return "callout"
  }

  static clone(node) {
    return new CalloutNode(node.__calloutType, node.__key)
  }

  // Returning null for an <aside> without the attribute declines the conversion,
  // so anything else keeps whatever handling it already had.
  static importDOM() {
    return {
      aside: (element) => element.hasAttribute("data-callout") ? { conversion: convertCalloutElement, priority: 1 } : null
    }
  }

  static importJSON(serializedNode) {
    return $createCalloutNode(serializedNode.calloutType).updateFromJSON(serializedNode)
  }

  constructor(calloutType = DEFAULT_CALLOUT_TYPE, key) {
    super(key)
    this.__calloutType = calloutType
  }

  // Declares the callout a boundary, the same way Lexical's own table cells do.
  // Block commands (lists, tables, dividers) climb to the nearest root or shadow
  // root before acting, so without this a list inserted in the body consumes the
  // whole callout; with it, they operate inside.
  isShadowRoot() {
    return true
  }

  // exportDOM is inherited: Lexical builds the exported element by calling
  // createDOM, so this one method covers both the editor and the saved HTML.
  createDOM() {
    const element = document.createElement("aside")
    element.setAttribute("data-callout", this.__calloutType)
    return element
  }

  updateDOM(prevNode, element) {
    if (prevNode.__calloutType !== this.__calloutType) {
      element.setAttribute("data-callout", this.__calloutType)
    }

    return false
  }

  exportJSON() {
    return { ...super.exportJSON(), calloutType: this.getCalloutType() }
  }

  getCalloutType() {
    return this.getLatest().__calloutType
  }

  setCalloutType(calloutType) {
    this.getWritable().__calloutType = calloutType
    return this
  }
}

// Subclassing ParagraphNode rather than writing a node from scratch means the
// title behaves like any other paragraph, including Enter producing an ordinary
// paragraph beneath it.
export class CalloutTitleNode extends ParagraphNode {
  static getType() {
    return "callout-title"
  }

  static clone(node) {
    return new CalloutTitleNode(node.__key)
  }

  static importDOM() {
    return {
      p: (element) => element.hasAttribute("data-callout-title") ? { conversion: convertCalloutTitleElement, priority: 1 } : null
    }
  }

  static importJSON(serializedNode) {
    return $createCalloutTitleNode().updateFromJSON(serializedNode)
  }

  createDOM(config) {
    const element = super.createDOM(config)
    element.setAttribute("data-callout-title", "")
    return element
  }

  // Lexical calls this on backspace at the start of a block, which is how a quote
  // collapses. Unwrapping the callout keeps the text and drops the container.
  collapseAtStart() {
    const callout = this.getParent()
    if (!$isCalloutNode(callout)) return false

    $unwrapCallout(callout)
    return true
  }
}

function convertCalloutElement(element) {
  const calloutType = element.getAttribute("data-callout")
  return { node: $createCalloutNode(CALLOUT_TYPES.includes(calloutType) ? calloutType : DEFAULT_CALLOUT_TYPE) }
}

function convertCalloutTitleElement() {
  return { node: $createCalloutTitleNode() }
}

export function $createCalloutNode(calloutType) {
  return $applyNodeReplacement(new CalloutNode(calloutType))
}

export function $createCalloutTitleNode() {
  return $applyNodeReplacement(new CalloutTitleNode())
}

export function $isCalloutNode(node) {
  return node instanceof CalloutNode
}

export function $isCalloutTitleNode(node) {
  return node instanceof CalloutTitleNode
}

// Wraps whole top-level blocks as callout children, the same way Lexxy's own
// quote toggle does, so lists, tables and code blocks survive intact. A leading
// paragraph becomes the title; otherwise the title defaults to the type name,
// matching an untitled Markdown callout.
export function $wrapInCallout(elements, calloutType) {
  const [ first, ...rest ] = elements
  const callout = $createCalloutNode(calloutType)
  const title = $createCalloutTitleNode()

  first.insertBefore(callout)

  if ($isParagraphNode(first)) {
    title.append(...first.getChildren())
    callout.append(title, ...rest)
    first.remove()
    title.selectEnd()
  } else {
    title.append($createTextNode(calloutLabel(calloutType)))
    callout.append(title, ...elements)
    title.select(0, title.getChildrenSize())
  }

  return callout
}

// Callouts must keep their title as the first child. Block-format commands
// (heading, list) know nothing about callouts and can replace the title node;
// converting whatever lands there back into a title makes those commands read
// as no-ops on the title rather than quietly destroying it. Registered as a
// node transform by the extension.
export function $enforceCalloutShape(callout) {
  const first = callout.getFirstChild()

  if (!first) {
    callout.remove()
  } else if (!$isCalloutTitleNode(first)) {
    const title = $createCalloutTitleNode()
    title.append(...$inlineContent(first))
    first.replace(title)
  }
}

function $inlineContent(node) {
  if (!$isElementNode(node) || node.isInline()) return [ node ]

  return node.getChildren().flatMap((child) => $inlineContent(child))
}

// Lifts the callout's children back out, demoting the title to a paragraph.
export function $unwrapCallout(callout) {
  callout.getChildren().forEach((child) => {
    const block = $isCalloutTitleNode(child) ? $createParagraphNode().append(...child.getChildren()) : child
    callout.insertBefore(block)
  })

  callout.remove()
}
