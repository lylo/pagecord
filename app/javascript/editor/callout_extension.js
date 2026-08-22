import * as Lexxy from "lexxy"
import {
  TOOLBAR_CALLOUT_TYPES,
  CalloutNode,
  CalloutTitleNode,
  calloutLabel,
  $enforceCalloutShape,
  $isCalloutNode,
  $unwrapCallout,
  $wrapInCallout
} from "editor/callout_node"

const {
  $getSelection,
  $isRangeSelection,
  $findMatchingParent,
  $createParagraphNode,
  KEY_ENTER_COMMAND,
  KEY_ARROW_DOWN_COMMAND,
  KEY_ARROW_UP_COMMAND,
  COMMAND_PRIORITY_LOW
} = Lexxy.Lexical

const ICON = `<svg viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg">
  <rect x="2" y="3" width="2.2" height="12" rx="1.1"/>
  <rect x="6.6" y="4.4" width="9.4" height="2" rx="1"/>
  <rect x="6.6" y="8.2" width="6.8" height="1.6" rx="0.8"/>
  <rect x="6.6" y="11.4" width="9.4" height="1.6" rx="0.8"/>
</svg>`

const SWATCH_ICON = `<svg viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg" style="fill: var(--callout-color)">
  <circle cx="9" cy="9" r="5"/>
</svg>`

// Teaches Lexxy about Obsidian-style callouts: the nodes that make them survive a
// round trip through the editor, the keys that get you back out of one, and a
// toolbar picker for the common types.
export default class CalloutExtension extends Lexxy.Extension {
  get enabled() {
    return this.editorElement.supportsRichText
  }

  // Lexxy derives the sanitizer's allowed tags from the editor's registered DOM
  // conversions, so registering CalloutNode is what permits <aside>. Only the
  // attributes need declaring here.
  get allowedElements() {
    return [
      { tag: "aside", attributes: [ "data-callout" ] },
      { tag: "p", attributes: [ "data-callout-title" ] }
    ]
  }

  get lexicalExtension() {
    return this.defineExtension({
      name: "pagecord/callouts",
      nodes: [ CalloutNode, CalloutTitleNode ],
      register(editor) {
        const teardowns = [
          editor.registerNodeTransform(CalloutNode, $enforceCalloutShape),
          editor.registerCommand(KEY_ENTER_COMMAND, $escapeOnEnter, COMMAND_PRIORITY_LOW),
          editor.registerCommand(KEY_ARROW_DOWN_COMMAND, $escapeDownwards, COMMAND_PRIORITY_LOW),
          editor.registerCommand(KEY_ARROW_UP_COMMAND, $escapeUpwards, COMMAND_PRIORITY_LOW)
        ]

        return () => teardowns.forEach((teardown) => teardown())
      }
    })
  }

  // <lexxy-toolbar-dropdown> already handles opening, closing, focus and keyboard
  // navigation for any trigger/panel pair, so the picker is markup plus one listener.
  initializeToolbar(lexxyToolbar) {
    const dropdown = document.createElement("lexxy-toolbar-dropdown")
    dropdown.className = "lexxy-editor__toolbar-dropdown lexxy-editor__toolbar-dropdown--callout"
    dropdown.innerHTML = `
      <button data-dropdown-trigger class="lexxy-editor__toolbar-button lexxy-editor__toolbar-button--chevron" type="button" name="callout" title="Callout" aria-haspopup="menu" aria-expanded="false">
        ${ICON}
      </button>
      <div data-dropdown-panel role="menu" hidden>
        <div class="lexxy-callout-types">
          ${TOOLBAR_CALLOUT_TYPES.map(calloutTypeItem).join("")}
        </div>
        <button type="button" role="menuitem" value="" title="Remove callout" class="lexxy-editor__toolbar-button lexxy-editor__toolbar-dropdown-reset">Remove</button>
      </div>
    `
    dropdown.addEventListener("click", this.#selectCalloutType)

    lexxyToolbar.querySelector("button[name=quote]").insertAdjacentElement("afterend", dropdown)
  }

  #selectCalloutType = (event) => {
    const item = event.target.closest("[role=menuitem]")
    if (!item) return

    this.editorElement.editor.update(() => $applyCalloutType(item.value))
    event.currentTarget.close()
  }
}

// data-callout on the button itself resolves --callout-color from the same mapping
// the rendered callouts use, so the swatches never drift from the real colours.
// The type name is the tooltip rather than a label, to keep the row compact.
function calloutTypeItem(calloutType) {
  const label = calloutLabel(calloutType)

  return `
    <button type="button" role="menuitem" class="lexxy-editor__toolbar-button" name="callout-${calloutType}" value="${calloutType}" data-callout="${calloutType}" title="${label}" aria-label="${label}">
      ${SWATCH_ICON}
    </button>
  `
}

// An empty type means "remove", so one menu drives create, change and remove.
// Operating on every selected top-level element mirrors Lexxy's quote toggle:
// a multi-block selection becomes one callout, and selected callouts are
// retyped or unwrapped together.
function $applyCalloutType(calloutType) {
  const selection = $getSelection()
  if (!$isRangeSelection(selection)) return

  const callouts = $selectedCallouts(selection)

  if (!calloutType) {
    callouts.forEach((callout) => $unwrapCallout(callout))
  } else if (callouts.length > 0) {
    callouts.forEach((callout) => callout.setCalloutType(calloutType))
  } else {
    const elements = $topLevelElementsInSelection(selection)
    if (elements.length > 0) $wrapInCallout(elements, calloutType)
  }
}

// The callout is a shadow root, so getTopLevelElement stops at its boundary and
// never returns the callout itself; find enclosing callouts by walking up.
function $selectedCallouts(selection) {
  const callouts = new Set()

  for (const node of selection.getNodes()) {
    const callout = $findMatchingParent(node, $isCalloutNode)
    if (callout) callouts.add(callout)
  }

  return Array.from(callouts)
}

function $topLevelElementsInSelection(selection) {
  const elements = new Set()

  for (const node of selection.getNodes()) {
    const element = node.getTopLevelElement()
    if (element) elements.add(element)
  }

  return Array.from(elements)
}

// The block the caret sits in, but only when it is a direct child of a callout.
// Walking the ancestors handles carets inside nested nodes such as links.
function $currentBlockInCallout() {
  const selection = $getSelection()
  if (!$isRangeSelection(selection) || !selection.isCollapsed()) return null

  return $findMatchingParent(selection.anchor.getNode(), (node) => $isCalloutNode(node.getParent()))
}

// Enter on an empty last line leaves the callout, the way lists and quotes do.
function $escapeOnEnter(event) {
  const block = $currentBlockInCallout()
  if (!block || block.getNextSibling() || block.getTextContentSize() > 0) return false

  const callout = block.getParent()
  const paragraph = $createParagraphNode()

  callout.insertAfter(paragraph)
  block.remove()
  if (callout.isEmpty()) callout.remove()
  paragraph.select()

  event?.preventDefault()
  return true
}

// Arrow keys only need help at the very start or end of the document, where there
// is no adjacent block for the caret to move into. Everywhere else this returns
// false and Lexical moves the caret itself.
function $escapeDownwards() {
  return $escapeVertically("getNextSibling", "insertAfter")
}

function $escapeUpwards() {
  return $escapeVertically("getPreviousSibling", "insertBefore")
}

function $escapeVertically(sibling, insert) {
  const block = $currentBlockInCallout()
  if (!block || block[sibling]()) return false

  const callout = block.getParent()
  if (callout[sibling]()) return false

  const paragraph = $createParagraphNode()
  callout[insert](paragraph)
  paragraph.select()

  return true
}
