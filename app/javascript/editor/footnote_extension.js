import * as Lexxy from "lexxy"
import {
  FootnoteRefNode,
  FootnotesNode,
  FootnoteItemNode,
  $enforceFootnoteShape,
  $footnotesList,
  $insertFootnote,
  $isFootnotesNode,
  $reconcileFootnotes
} from "editor/footnote_node"

const {
  $findMatchingParent,
  $getSelection,
  $isRangeSelection,
  COMMAND_PRIORITY_NORMAL
} = Lexxy.Lexical

// Marks our own renumbering pass so the update listener ignores it and does not
// re-trigger itself.
const RECONCILE_TAG = "pagecord/footnotes-reconciled"

// fill on the <svg> itself because the toolbar's currentColor rule only reaches
// <path>, and these are rects.
const ICON = `<svg viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg" fill="currentColor">
  <rect x="2" y="4.2" width="9" height="1.6" rx="0.8"/>
  <rect x="12.6" y="2.4" width="3.4" height="3.4" rx="1"/>
  <rect x="2" y="8.2" width="14" height="1.6" rx="0.8"/>
  <rect x="2" y="12.2" width="6" height="1.6" rx="0.8"/>
</svg>`

// Teaches Lexxy about footnotes: the nodes that make them survive a round trip
// through the editor, a toolbar button that inserts one, and the numbering that
// keeps markers and notes in step as the post is edited.
export default class FootnoteExtension extends Lexxy.Extension {
  get enabled() {
    return this.editorElement.supportsRichText
  }

  // Lexxy derives the sanitizer's allowed tags from the editor's registered DOM
  // conversions, so registering the nodes is what permits these tags. Attributes
  // are another matter: id is absent from Lexxy's global attribute list, so
  // without declaring it here the anchors would work in the editor and be
  // stripped on save. Declarations from different extensions are merged, so
  // asking for id on li does not disturb the gem's own claim on value.
  get allowedElements() {
    return [
      { tag: "sup", attributes: [ "data-footnote-ref", "id" ] },
      { tag: "ol", attributes: [ "data-footnotes" ] },
      { tag: "li", attributes: [ "id" ] }
    ]
  }

  get lexicalExtension() {
    return this.defineExtension({
      name: "pagecord/footnotes",
      nodes: [ FootnoteRefNode, FootnotesNode, FootnoteItemNode ],
      register(editor) {
        const teardowns = [
          editor.registerCommand("insertFootnote", $onInsertFootnote, COMMAND_PRIORITY_NORMAL),

          // The shape transform makes every block command a no-op inside a note,
          // but the upload pair open a native file picker, which no transform can
          // take back. Swallowed here instead: the gem's handlers sit at priority
          // 0, so NORMAL runs first, and returning false elsewhere falls through.
          editor.registerCommand("uploadImage", $swallowInsideFootnote, COMMAND_PRIORITY_NORMAL),
          editor.registerCommand("uploadFile", $swallowInsideFootnote, COMMAND_PRIORITY_NORMAL),

          editor.registerNodeTransform(FootnoteItemNode, $enforceFootnoteShape),

          // Deleting a marker leaves nothing dirty for a node transform to fire
          // on, so numbering has to be driven from the update listener instead.
          // history-merge keeps it out of the undo stack: undo should step back
          // over the author's edit, not over the renumbering that followed it.
          editor.registerUpdateListener(({ tags }) => {
            if (tags.has(RECONCILE_TAG) || !editor.read($footnotesList)) return

            editor.update($reconcileFootnotes, { tag: [ "history-merge", RECONCILE_TAG ] })
          })
        ]

        return () => teardowns.forEach((teardown) => teardown())
      }
    })
  }

  // Toolbar buttons are declarative in Lexxy: data-command is dispatched on the
  // editor, already inside an update. Next to the link button because a footnote
  // is an inline insert, where the callout picker sits by the block controls.
  initializeToolbar(lexxyToolbar) {
    const button = document.createElement("button")
    button.type = "button"
    button.name = "footnote"
    button.title = "Footnote"
    button.className = "lexxy-editor__toolbar-button"
    button.dataset.command = "insertFootnote"
    button.innerHTML = ICON

    // Anchored on the dropdown element, not its button[name=link] trigger, which
    // lives inside it: inserting after the trigger would nest the button in the
    // dropdown, where it is both misplaced and missed by Lexxy's data-lexxy-extension
    // tagging, so it would duplicate on every editor reconnect.
    lexxyToolbar.querySelector("lexxy-link-dropdown").insertAdjacentElement("afterend", button)
  }
}

// The caret lands in the new note rather than staying beside the marker, so the
// author can type the note straight away.
function $onInsertFootnote() {
  const selection = $getSelection()
  if (!$isRangeSelection(selection)) return false

  // A footnote on a footnote has nowhere sensible to go: the marker would sit where
  // $footnoteRefs deliberately never looks, so it could never be numbered or paired.
  if ($insideFootnote(selection)) return true

  $insertFootnote(selection).selectStart()
  return true
}

// Claims the command, so the gem's handler never runs, without inserting anything.
function $swallowInsideFootnote() {
  return $insideFootnote($getSelection())
}

function $insideFootnote(selection) {
  return $isRangeSelection(selection) &&
    Boolean($findMatchingParent(selection.anchor.getNode(), $isFootnotesNode))
}
