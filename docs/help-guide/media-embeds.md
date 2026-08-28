---
title: "Media embeds"
published: true
published_at: 2026-03-30T00:00:00+00:00
---

Pagecord can automatically turn links into rich embeds. Paste a supported URL on its own line – with no other text around it – and it will be replaced by an embedded player or preview when readers view your post.

## Supported services

| Service | What embeds |
|---|---|
| **YouTube** | Videos, Shorts, live streams, and playlists |
| **YouTube Music** | Tracks and public playlists (played via the standard YouTube player) |
| **Spotify** | Tracks, albums, playlists, podcasts, and shows |
| **Apple Music** | Songs, albums, and playlists |
| **Tidal** | Tracks, albums, and playlists |
| **Bandcamp** | Albums and tracks |
| **Transistor** | Podcast episodes and shows |
| **Strava** | Activity pages |
| **GitHub** | Gists |
| **Bluesky** | Individual posts |
| **Images** | Direct image URLs (jpg, png, gif, webp, svg) |

## How it works

Direct image URLs are worth knowing about on Classic: if you host a picture somewhere else, embedding it by URL costs nothing against your upload allowance.

Paste the URL on its own line, with no other text around it. The URL can be a plain link or a hyperlink, as long as the visible text is the URL itself. When a reader views your post, the link is replaced with the embed automatically.

For example, pasting this on its own line will display a Spotify player:

```
https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT
```

## Embeds in the editor

Most embeds are shown in the editor as you write, so you can see the player in place rather than a bare URL. Strava activities and direct image URLs are the exceptions: those stay as links while writing and appear in the published post.

Only the link is saved, never the player. That means an embed keeps working if the service changes how its player is built, and it stays a plain link anywhere a player cannot go – an RSS reader or an email newsletter.
