---
title: "Callouts"
published: true
published_at: 2026-08-06T21:00:00+00:00
---

Callouts pull something out of the flow of a post so a reader cannot scroll past it. Use them for a warning, a tip, or an aside that would interrupt the paragraph it belongs to.

## Writing a callout

A callout is a blockquote whose first line begins with a type in square brackets:

```
> [!note] Worth knowing
> Callouts are a good way to flag something without breaking your paragraph.
```

Everything after the type on that first line becomes the title. Leave it off and the type name is used instead:

```
> [!tip]
> This callout is titled "Tip".
```

This is the same syntax Obsidian uses, so notes written there publish to Pagecord unchanged.

## The types

Obsidian's full set of callout types is supported:

`note`, `info`, `todo`, `abstract`, `tip`, `success`, `question`, `warning`, `failure`, `danger`, `bug`, `example` and `quote`.

Obsidian's aliases work too, and render as the type they are an alias of. So `[!important]` renders as a tip, and `[!caution]` renders as a warning, exactly as they do in Obsidian. The title still shows the word you typed.

Related types share a colour, again following Obsidian. A type that is not on the list falls back to a note, keeping the word you typed as the title, so a typo never shows the raw `[!marker]` in your published post.

## Using the editor

In the Pagecord editor, the callout button sits next to the quote button in the toolbar. It opens a small menu with a coloured dot for each of the most common types. Hover over a dot to see which type it is. The full set is always available in Markdown.

- Choose a colour to turn the current paragraph into a callout, or to change the type of one you are already in
- Press **Enter** on an empty last line to move back out of a callout
- Press **Backspace** at the very start of the title to remove the callout and keep the text
- Choose **Remove** from the menu to do the same thing

Callouts written in Markdown stay callouts when you open the post in the editor, and callouts made in the editor export as the same Markdown syntax.

## What a callout can contain

Anything a blockquote can hold: bold and italic text, inline code, links, and multiple paragraphs.

```
> [!important] Worth knowing
> The title is a separate element, so it stays readable even where styling is stripped.
>
> Feed readers and email clients often do exactly that.
```

## A note on feeds and exports

Callouts keep their colour and background on your blog. In RSS readers, email digests and blog exports, styling is often stripped by the receiving app. When that happens the title still appears on its own line, so the callout stays readable as a titled quote.
