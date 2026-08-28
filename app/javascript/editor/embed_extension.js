import * as Lexxy from "lexxy"
import { EmbedNode, $embedLinkParagraph } from "editor/embed_node"

const { ParagraphNode } = Lexxy.Lexical

// Teaches Lexxy to show media embeds as they will appear on the blog. Nothing about
// the stored post changes: the node exports the same paragraph and link it was
// built from, so this is a preview and not a new way of writing embeds.
export default class EmbedExtension extends Lexxy.Extension {
  get enabled() {
    return this.editorElement.supportsRichText
  }

  // No allowedElements. The iframe only ever exists in the editor's own DOM, never
  // in anything handed to the sanitizer, which is the point of the design.
  get lexicalExtension() {
    return this.defineExtension({
      name: "pagecord/media-embeds",
      nodes: [ EmbedNode ],
      register(editor) {
        return editor.registerNodeTransform(ParagraphNode, $embedLinkParagraph)
      }
    })
  }
}
