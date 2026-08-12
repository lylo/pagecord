import * as Lexxy from "lexxy"

// Lexxy's toolbar order is fixed in its default template, and extensions append
// their buttons wherever they like, so left alone the bar ends up grouped by
// whoever added what rather than by what an author reaches for.
//
// The order doubles as a priority list. Lexxy reclaims width by moving the last
// overflowable buttons into the "…" menu, so whatever sits at the end here is
// what disappears first when the bar is cramped.
//
// Two things constrain it. Only direct-child <button> elements can overflow, so
// the dropdown controls (headings, highlight, link, callout) hold their width
// wherever they sit; and image carries data-prevent-overflow, so it never moves.
//
// Hence callout and footnote sitting with quote rather than at the end: the three
// all insert a block of set-apart text, and parked behind the callout dropdown at
// the end, footnote was the first thing to disappear on a laptop.
const ORDER = [
  "image", "file",
  "bold", "italic", "strikethrough", "underline",
  "format", "highlight", "link",
  "unordered-list", "ordered-list",
  "quote", "callout", "footnote",
  "code", "table", "divider"
]

export default class ToolbarOrderExtension extends Lexxy.Extension {
  get enabled() {
    return this.editorElement.supportsRichText
  }

  // Registered last so the buttons the other extensions add are already present.
  // Reordering existing children is idempotent, which matters because Lexxy calls
  // this again whenever the editor reconnects.
  initializeToolbar(lexxyToolbar) {
    const ordered = ORDER.map((name) => toolbarItem(lexxyToolbar, name)).filter(Boolean)

    // Undo, redo and the overflow menu itself are left to fall out at the end in
    // the order the gem had them, so they keep their margin-inline-start: auto and
    // anything a future Lexxy release adds still lands somewhere sensible.
    const rest = Array.from(lexxyToolbar.children).filter((child) => !ordered.includes(child))

    lexxyToolbar.append(...ordered, ...rest)
  }
}

// Some controls are a bare button, others a custom element wrapping their trigger.
// Either way it is the toolbar's direct child that has to move.
function toolbarItem(lexxyToolbar, name) {
  let node = lexxyToolbar.querySelector(`[name="${name}"]`)
  while (node && node.parentElement !== lexxyToolbar) node = node.parentElement

  return node
}
