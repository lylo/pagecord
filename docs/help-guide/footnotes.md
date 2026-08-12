---
title: "Footnotes"
published: true
published_at: 2026-08-11T21:00:00+00:00
---

Footnotes move a citation, a caveat or an aside out of the sentence it belongs to and down to the foot of the post, where a reader can take it or leave it. They suit reference-heavy writing that would otherwise fill up with parentheses.

## Writing a footnote

A footnote is two parts: a reference where you want the marker, and a definition somewhere else in the post.

```
Redcarpet follows the original Markdown.pl here[^1].

[^1]: Which is why a blank line does not end a blockquote.
```

The label between the brackets is just a name for tying the two halves together. It never appears in the published post, so use whatever is easiest to keep track of:

```
Two claims worth backing up[^census] and one that is not[^hunch].

[^census]: Office for National Statistics, 2021.
[^hunch]: No source. I made this up.
```

Definitions can go anywhere in the post. Wherever you put them, the notes are collected into a numbered list at the end, in the order their markers appear in the text. The numbering is worked out for you, so moving a paragraph around never leaves the numbers wrong.

## What a footnote can contain

Anything a paragraph can hold: bold and italic text, inline code, and links. Indent by four spaces to carry a note across more than one paragraph.

```
The measurement was repeated[^method].

[^method]: Three runs, discarding the first.

    The first run warms the cache, so including it roughly halves the figure.
```

## Using the editor

In the Pagecord editor, the footnote button sits next to the link button in the toolbar.

- Put the cursor where you want the marker and press the button. The marker is inserted and the cursor moves to the new note at the foot of the post, ready for you to type
- Delete a marker to delete its note, and delete a note to delete its marker. The two always travel together
- The remaining footnotes renumber themselves straight away, whether you delete one or move a paragraph containing one

Markers are not editable, because the numbers are worked out rather than typed. The cursor sits either side of a marker but never inside it, and Backspace removes the whole thing rather than a digit at a time.

A note holds ordinary text, so bold, italic and links all work inside one. Headings, lists, quotes, tables, images and dividers do not: those buttons do nothing rather than restructuring the note. Pressing the footnote button while the cursor is already in a note does nothing either, since a footnote on a footnote has nowhere to point.

Footnotes written in Markdown stay footnotes when you open the post in the editor, and footnotes made in the editor export as the same Markdown syntax.

## A note on feeds, emails and excerpts

On your blog, a marker is a link down to its note. In email digests this link does nothing, because mail apps strip the anchors it needs, but the notes still appear as a numbered list at the foot of the post. RSS readers vary.

If a post has an excerpt break, markers are left out of the excerpt shown on your index page, since the notes they point at are further down the full post.

## A few things to know

- A reference with no matching definition is left exactly as you typed it, so a mistyped label shows up rather than disappearing quietly
- A definition that nothing refers to is left out of the published post
- Referring to the same definition twice gives you two markers with the same number
