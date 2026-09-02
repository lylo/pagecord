import * as Lexxy from "lexxy"

const { DecoratorNode, $applyNodeReplacement, $getNodeByKey } = Lexxy.Lexical

// The prompt under a freshly pasted link asking whether to expand it into a
// preview. Never stored: exportDOM hands back the paragraph and link, so a post
// saved with the question still open holds nothing but the link. Expanding
// replaces the node with ordinary content built from the link's Open Graph
// tags: the image as a regular attachment, the title as a bold link, the
// description as a paragraph, each editable and deletable on its own.
export class UnfurlNode extends DecoratorNode {
  __url

  static getType() {
    return "link-unfurl"
  }

  static clone(node) {
    return new UnfurlNode(node.__url, node.__key)
  }

  static importJSON(serializedNode) {
    return $createUnfurlNode(serializedNode.url).updateFromJSON(serializedNode)
  }

  constructor(url, key) {
    super(key)
    this.__url = url
  }

  isInline() {
    return false
  }

  createDOM(_config, editor) {
    const element = document.createElement("div")
    element.className = "link-unfurl"
    element.appendChild(linkTo(this.__url))
    element.appendChild(this.#createActions(editor))
    return element
  }

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

  #createActions(editor) {
    const actions = document.createElement("div")
    actions.className = "link-unfurl__actions"
    actions.append(
      button("Show preview", () => this.#expand(editor, actions)),
      button("Dismiss", () => this.#replaceWith(editor, linkParagraphHtml(this.__url)))
    )
    return actions
  }

  async #expand(editor, actions) {
    actions.replaceChildren("Fetching preview…")

    const preview = await fetchPreview(this.__url)

    if (preview) {
      this.#replaceWith(editor, previewHtml(this.__url, preview))
    } else {
      actions.replaceChildren("No preview available")
      setTimeout(() => this.#replaceWith(editor, linkParagraphHtml(this.__url)), 2000)
    }
  }

  #replaceWith(editor, html) {
    const editorElement = editor.getRootElement().closest("lexxy-editor")

    editor.update(() => {
      const node = $getNodeByKey(this.getKey())
      if (!node) return

      const doc = new DOMParser().parseFromString(html, "text/html")
      const replacements = editorElement.$generateNodesFromDOM(doc)

      let previous = node
      for (const replacement of replacements) {
        previous.insertAfter(replacement)
        previous = replacement
      }
      node.remove()

      previous.selectEnd()
    })
  }
}

function linkTo(url) {
  const link = document.createElement("a")
  link.setAttribute("href", url)
  link.textContent = url

  return link
}

function button(label, action) {
  const element = document.createElement("button")
  element.type = "button"
  element.textContent = label

  // The clicks stay in the prompt: reaching Lexical's own click handling would
  // select the node the action is busy replacing, and the whole update batch
  // rolls back.
  element.addEventListener("mousedown", (event) => event.stopPropagation())
  element.addEventListener("click", (event) => {
    event.preventDefault()
    event.stopPropagation()
    action()
  })

  return element
}

function linkParagraphHtml(url) {
  const paragraph = document.createElement("p")
  paragraph.appendChild(linkTo(url))

  return paragraph.outerHTML
}

// Built from DOM elements rather than an interpolated string, because the title
// and description are whatever the fetched page put in its meta tags.
function previewHtml(url, preview) {
  const container = document.createElement("div")

  if (preview.image) {
    const attachment = document.createElement("action-text-attachment")
    attachment.setAttribute("sgid", preview.image.attachable_sgid)
    attachment.setAttribute("url", preview.image.url)
    attachment.setAttribute("content-type", preview.image.content_type)
    attachment.setAttribute("filename", preview.image.filename)
    if (preview.image.width) attachment.setAttribute("width", preview.image.width)
    if (preview.image.height) attachment.setAttribute("height", preview.image.height)
    container.appendChild(attachment)
  }

  const caption = document.createElement("p")
  const strong = document.createElement("strong")
  strong.appendChild(Object.assign(linkTo(url), { textContent: preview.title }))
  caption.appendChild(strong)

  if (preview.description) {
    caption.appendChild(document.createElement("br"))
    caption.appendChild(document.createTextNode(preview.description))
  }

  container.appendChild(caption)

  return container.innerHTML
}

async function fetchPreview(url) {
  try {
    const token = document.querySelector('[name="csrf-token"]')?.content
    const response = await fetch("/app/link_previews", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(token && { "X-CSRF-Token": token })
      },
      body: JSON.stringify({ url })
    })

    if (!response.ok) return null
    return await response.json()
  } catch {
    return null
  }
}

export function $createUnfurlNode(url) {
  return $applyNodeReplacement(new UnfurlNode(url))
}
