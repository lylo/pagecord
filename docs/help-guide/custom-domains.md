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
ALIAS @ → proxy.pagecord.com
CNAME www → proxy.pagecord.com
```

#### **Option 2: CNAME only (Cloudflare users)**

```javascript
CNAME @ → proxy.pagecord.com
CNAME www → proxy.pagecord.com
```

#### **Option 3: A record (if ALIAS not supported)**

```javascript
A @ → 94.130.191.219
CNAME www → proxy.pagecord.com
```

_<mark><em>Note: The IP address may change. Use ALIAS if your provider supports it.</em></mark>_

### For subdomains (e.g. blog.mydomain.com)

```javascript
CNAME blog → proxy.pagecord.com
```

## Step 2: Add the domain in Pagecord

1. Go to **Settings** → **Blog Settings**
2. Enter your domain in the **Custom Domain** field
3. Click **Update**

Pagecord will verify your DNS and set up SSL automatically. This can take a few minutes.

## Cloudflare users

Your records can be either:

- **DNS only** (grey cloud) – the simplest setup, since Pagecord already provides CDN and SSL.
- **Proxied** (orange cloud), if you want Cloudflare's CDN and protections. Set your SSL/TLS mode to **Full (Strict)** to avoid certificate errors.

If you proxy, make sure no redirect or firewall rule blocks `/.well-known/acme-challenge/` on your domain. I issue and renew your SSL certificate through that path, so blocking it will leave your site showing certificate errors.

## Removing a custom domain

To remove your custom domain, clear the Custom Domain field in Blog Settings and click Update. Don't forget to remove the DNS records too.

