---
title: "Connecting Claude and ChatGPT"
published: true
published_at: 2026-10-18T09:00:00+00:00
---

Connect Pagecord to Claude or ChatGPT and design your blog by chatting. Try a new theme, adjust the colours, or write custom CSS and code. You can also manage posts – no terminal or API key needed.

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

For Free, Pro and Max plans:

1. In Claude, open **Customize > Connectors** and choose **+ Add > Add custom connector**
2. Give it a name, such as Pagecord, and paste the connector URL
3. Continue through the setup, choose **Register automatically** for the OAuth client, then click **Add**
4. In a chat, open **+ > Connectors** and turn on Pagecord
5. Click **Connect**, log in if asked, choose which blog to connect if you have more than one, and click **Allow**

On Team or Enterprise plans, an organisation owner needs to add Pagecord as an organisation connector first. You can then connect to it from **Customize > Connectors**.

## Connecting ChatGPT

Adding a custom MCP server needs a paid ChatGPT plan and works on the web. In Business and Enterprise workspaces, an admin may need to allow it.

1. In ChatGPT on the web, open **Settings > Plugins**, choose **Browse directory**, then **Add > Add custom MCP server**
2. Enter a name, such as Pagecord, and paste the connector URL
3. Choose **OAuth** for authentication, review the access warning, then choose **Create as a plugin**
4. Review the tools ChatGPT finds, then create the plugin
5. In a new chat, select Pagecord from the tools menu and connect to Pagecord when prompted

See [OpenAI's setup guide](https://help.openai.com/en/articles/12584461-connecting-custom-mcp-servers-in-chatgpt) for current workspace and account requirements.

## Logging in from the connect window

Logging in with your password is quickest, because you stay in the same window. If you use a magic link instead, open it in the same browser and the connect page carries on where it left off.

## What it can do

Once connected, your assistant can:

- List your published posts and drafts
- Read a post, with its content as Markdown
- Write new posts. They're saved as drafts unless you ask for them to be published
- Edit a post's title, content, tags, slug or publish date, including scheduling it
- Move a post to the trash. You can restore it from the Trash in your dashboard
- Read and change your theme, font, page width, layout and custom colours
- Read and change your custom CSS and footer, and if you're a subscriber, your custom head and body HTML
- Read your blog's real HTML, so its CSS targets the right elements
- Check CSS before saving it, and tell you exactly what isn't allowed

It can't see your analytics, subscribers or account settings, and it can't send emails to subscribers.

## Designing with an assistant

Your assistant reads the [custom CSS guide](custom-css.md) before it starts – the colour variables, how dark mode works, and what custom CSS can contain – and keeps a copy of your custom CSS so it can put it back. A few things help:

- Use **Preview** in **Settings** → **Custom code** to see its CSS before you save it
- Check the design in light and dark mode, and on your phone
- If you want to go back, ask it to restore the custom CSS it copied at the start

## Disconnecting

Go to **Settings > API** and click **Disconnect** next to the app. It stops working straight away. You can also remove the connector from Claude or ChatGPT, but disconnecting in Pagecord is what revokes its access.

## Claude Code and other MCP clients

Tools that let you set request headers, such as Claude Code, can skip the login step and use your [API key](api.md) instead:

```
claude mcp add --transport http pagecord https://api.pagecord.com/mcp \
  --header "Authorization: Bearer YOUR_API_KEY"
```
