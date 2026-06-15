---
title: "Media embeds"
published: true
published_at: 2026-03-30T00:00:00+00:00
---

Pagecord can turn links into rich embeds. Paste a supported URL on its own line to embed it automatically, or use an explicit `{{ embed ... }}` tag in posts and pages.

## Supported services

| Service | What embeds | How to use |
|---|---|---|
| **YouTube** | Videos, Shorts, and live streams | Automatic or `{{ embed ... }}` |
| **Spotify** | Tracks, albums, playlists, podcasts, and shows | Automatic or `{{ embed ... }}` |
| **Apple Music** | Songs, albums, and playlists | Automatic or `{{ embed ... }}` |
| **TIDAL** | Tracks, albums, and playlists | Automatic or `{{ embed ... }}` |
| **Bandcamp** | Albums and tracks | Automatic or `{{ embed ... }}` |
| **Transistor** | Podcast episodes and shows | Automatic or `{{ embed ... }}` |
| **Strava** | Activity pages | Automatic or `{{ embed ... }}` |
| **GitHub** | Gists | Automatic or `{{ embed ... }}` |
| **Bluesky** | Individual posts | Automatic or `{{ embed ... }}` |
| **Images** | Direct image URLs (jpg, png, gif, webp, svg) | Automatic or `{{ embed ... }}` |
| **Checkvist** | Public lists | Automatic or `{{ embed ... }}` |

## Automatic embeds

For automatic embeds, paste the URL on its own line, with no other text around it. The URL can be a plain link or a hyperlink, as long as the visible text is the URL itself. When a reader views your post, the link is replaced with the embed automatically.

For example, pasting this on its own line will display a Spotify player:

```
https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT
```

## Explicit embeds

You can also wrap a URL in an `embed` tag:

```
{{ embed https://bsky.app/profile/pagecord.com/post/3mhpkv6y5e22v }}
```

You can use explicit embeds in posts and pages. If the editor turns the URL into a hyperlink, that's fine, as long as the visible link text is still the URL.

## Embeds in the editor

Embeds are not rendered in the editor – you'll see the raw URL while writing. They only appear in the published (or previewed) post.
