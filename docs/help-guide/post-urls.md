---
title: "Post URLs"
published: true
published_at: 2026-08-28T09:00:00+01:00
---

Pagecord posts have the most simple URL structure – they're just a slug. If you'd rather have something different, maybe because you're moving from somewhere like WordPress or Blogger, you can now choose different formats for your post URLs.

## The three formats

- **`/my-post`** – the default
- **`/blog/my-post`** – your posts in a folder, which you can name yourself
- **`/2026/08/23/my-post`** – dated - the classic WordPress format

Whichever you pick applies to every post on your blog. There's no per-post setting.

## Changing the format

1. Go to **Settings** → **Blog Settings**
2. Scroll down to **Advanced**
3. Pick a format under **Post URLs**
4. If you choose the folder option, type the folder name you want
5. Click **Update**

## Nothing breaks when you switch

Your old links will still work. Anything that isn't the format you've chosen redirects permanently to the one that is, so old links, bookmarks and search results all still land on the right post. It works in both directions too, so you can change your mind as often as you like.

## Naming your folder

Call it whatever you like: `blog`, `notes`, `writing`, `blabberings`. Lowercase letters and numbers, with hyphens or underscores if you need them, up to 30 characters (note there are some reserved names in Pagecord, but this will be highlighted in an error message if you hit them).

Note that choosing a folder moves your list of posts into it too. With a folder called `notes`, your posts live at `/notes`, and the old `/posts` redirects there.

## Coming from Blogger

Blogger publishes posts at addresses like `/2013/07/my-post.html`. That isn't a format you can pick here, but Pagecord recognises those addresses and redirects them to whichever format you're using, so links to your old Blogger posts carry on working.

## Things worth knowing

This is only for posts. Pages aren't affected, so `/about` stays at `/about` whichever option you pick.

Your slug is what identifies a post, so it stays unique across your whole blog even when the address carries a date. Two posts published in different months still can't share a slug – the second one picks up a short suffix to tell them apart.
