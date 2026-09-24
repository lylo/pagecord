---
title: "Connecting Claude and ChatGPT"
published: true
published_at: 2026-09-24T12:00:00+00:00
---

Connect Pagecord to Claude or ChatGPT and manage your blog by chatting. Ask it to draft a post from your notes, publish a draft, tidy up tags, or try a new theme – no terminal or API key needed.

Pagecord works as an MCP server (Model Context Protocol, the standard AI assistants use to talk to other apps). Connecting is a Premium feature.

<div>
{{ table_of_contents | heading: "Table of Contents" }}
</div>

## The connector URL

```
https://api.pagecord.com/mcp
```

You can also copy it from **Settings > API** in your dashboard.

## Connecting Claude

1. In Claude, open **Settings > Connectors** and choose **Add custom connector**
2. Give it a name, such as Pagecord, and paste the connector URL
3. Click **Connect**. A Pagecord window opens
4. Log in if asked, choose which blog to connect if you have more than one, and click **Allow**

The connector then works in every Claude chat. Turn it on from the tools menu in a conversation if it isn't already.

## Connecting ChatGPT

1. In ChatGPT, open **Settings > Apps & Connectors > Advanced settings** and turn on **Developer mode**
2. Back in **Apps & Connectors**, choose **Create**
3. Paste the connector URL, choose **OAuth** for authentication, and create it
4. Log in to Pagecord when the window opens and click **Allow**

## Logging in from the connect window

Logging in with your password is quickest, because you stay in the same window. If you use a magic link instead, open it in the same browser and the connect page carries on where it left off.

## What it can do

Once connected, your assistant can:

- List your published posts and drafts
- Read a post, with its content as Markdown
- Write new posts. They're saved as drafts unless you ask for them to be published
- Edit a post's title, content, tags, slug or publish date, including scheduling it
- Move a post to the trash. You can restore it from the Trash in your dashboard
- Read and change your theme, font, page width, layout, custom colours and custom CSS

It can't see your analytics, subscribers or account settings, and it can't send emails to subscribers.

## Disconnecting

Go to **Settings > API** and click **Disconnect** next to the app. It stops working straight away. You can also remove the connector from Claude or ChatGPT, but disconnecting in Pagecord is what revokes its access.

## Claude Code and other MCP clients

Tools that let you set request headers, such as Claude Code, can skip the login step and use your [API key](api.md) instead:

```
claude mcp add --transport http pagecord https://api.pagecord.com/mcp \
  --header "Authorization: Bearer YOUR_API_KEY"
```
