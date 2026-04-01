---
title: "Contact form"
published: true
published_at: 2025-12-18T16:37:19+00:00
---

Let readers get in touch with you directly from your blog. Add a contact form to any page and receive messages straight to your inbox. Your email address isn't revealed to the sender.

This is a premium feature.

## Adding a contact form

Contact forms are embedded using a dynamic variable on a [page](creating-pages.md). Create a page (e.g. "Contact") and add the following:

```
{{ contact_form }}
```

The form asks the reader for their name, email address, and a message.

## How it works

- When someone submits the form, their message is emailed directly to the email address you signed up to Pagecord with
- Messages are not stored after being sent
- Your email address is never shown to the sender
- You can reply back normally from your email client to continue the conversation

## Tips

- Add a "Contact" page to your [navigation menu](setting-up-navigation.md) so readers can easily find it
- You can combine the contact form with other content on the same page — just add `{{ contact_form }}` wherever you want it to appear
- Submissions are automatically scanned for spam and deleted if they are flagged
