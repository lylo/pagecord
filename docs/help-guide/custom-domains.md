---
title: "Custom domains"
published: true
published_at: 2025-12-18T16:38:15+00:00
---

Premium feature. Use your own domain name instead of yourname.pagecord.com.

## Step 1: Configure your DNS

Before adding your domain in Pagecord, you need to point it to our servers. Add these records with your DNS provider:

### For root domains (e.g. mydomain.com)

#### **Option 1: ALIAS + CNAME (recommended)**

```javascript
ALIAS @ → domains.pagecord.com
CNAME www → domains.pagecord.com
```

#### **Option 2: CNAME only (Cloudflare users)**

```javascript
CNAME @ → domains.pagecord.com
CNAME www → domains.pagecord.com
```

If you're using Cloudflare DNS, set your records to **DNS only** (gray cloud).

#### **Option 3: A record (if ALIAS not supported)**

```javascript
A @ → 94.130.191.219
CNAME www → domains.pagecord.com
```

_<mark><em>Note: The IP address may change. Use ALIAS if your provider supports it.</em></mark>_

### For subdomains (e.g. blog.mydomain.com)

```javascript
CNAME blog → domains.pagecord.com
```

## Step 2: Add the domain in Pagecord

1. Go to **Settings** → **Blog Settings**
2. Enter your domain in the **Custom Domain** field
3. Click **Update**

Pagecord will verify your DNS and set up SSL automatically. This can take a few minutes. You can check the SSL status on your Blog Settings page.

## Cloudflare users

Set your DNS records to **DNS only** (gray cloud) for the simplest setup, since Pagecord already provides CDN and SSL.

## Migrating from proxy.pagecord.com

If you previously set up your domain with `proxy.pagecord.com`, it will continue to work. However, we recommend updating your DNS records to point to `domains.pagecord.com` for improved performance and edge caching.

## Removing a custom domain

To remove your custom domain, clear the Custom Domain field in Blog Settings and click Update. Don't forget to remove the DNS records too.
