import * as Lexxy from "lexxy"
import { UnfurlNode, $createUnfurlNode } from "editor/unfurl_node"
import { $moveCaretAfter } from "editor/embed_node"
import { isSameTarget, matchingSite, mediaSites } from "media_sites"

const { ParagraphNode, PASTE_COMMAND, COMMAND_PRIORITY_CRITICAL } = Lexxy.Lexical

// Every media site, not just the editor's subset: a Strava or image link embeds
// on the published blog, so offering to unfurl it would promise one thing and
// render another.
const SITES = mediaSites()

// Offers to expand a pasted link into a preview of what it points at. Pasting
// is the only trigger, so opening an old post never sprouts prompts over links
// the author already chose to leave alone.
export default class UnfurlExtension extends Lexxy.Extension {
  get enabled() {
    return this.editorElement.supportsRichText
  }

  get lexicalExtension() {
    // The URL the last paste consisted of, if that is all it was. The paste
    // settles into a link node asynchronously, so the transform matches on the
    // URL itself rather than trying to catch the right update.
    let pastedUrl = null

    return this.defineExtension({
      name: "pagecord/link-unfurls",
      nodes: [ UnfurlNode ],
      register(editor) {
        const unregisterPaste = editor.registerCommand(PASTE_COMMAND, (event) => {
          const text = event.clipboardData?.getData("text/plain")?.trim()
          pastedUrl = text?.match(/^https:\/\/\S+$/) ? text : null
          return false
        }, COMMAND_PRIORITY_CRITICAL)

        const unregisterTransform = editor.registerNodeTransform(ParagraphNode, (paragraph) => {
          if (pastedUrl && $offerUnfurl(paragraph, pastedUrl)) pastedUrl = null
        })

        return () => {
          unregisterPaste()
          unregisterTransform()
        }
      }
    })
  }
}

function $offerUnfurl(paragraph, url) {
  const children = paragraph.getChildren()
  if (children.length !== 1) return false
  if (!isUnfurlableLinkNode(children[0], url)) return false

  const prompt = $createUnfurlNode(children[0].getURL())
  paragraph.replace(prompt)
  $moveCaretAfter(prompt)
  return true
}

function isUnfurlableLinkNode(node, url) {
  return node.getType() === "link" &&
    isSameTarget(node.getURL(), url) &&
    isSameTarget(node.getURL(), node.getTextContent().trim()) &&
    matchingSite(node.getURL(), SITES) === null
}
