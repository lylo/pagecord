# Security

Pagecord is a hosted service. The code here is the code running at pagecord.com, and there are no versioned releases: a fix is deployed as soon as it lands on `main`.

## Reporting a vulnerability

Email **security@pagecord.com** with a description of the issue and steps to reproduce it. Please don't open a public GitHub issue for anything security-related.

You'll get an acknowledgement, and an update once the issue is confirmed or ruled out. There is no bug bounty.

## Scope

In scope:

- pagecord.com, blog subdomains and custom domains
- The API (`api.pagecord.com`)
- Code in this repository

Out of scope:

- Findings that need a paid account to attack only that same account
- Rate limiting, missing security headers, email configuration (SPF, DKIM, DMARC) and other "best practice" reports without a demonstrated impact
- Denial of service
- Social engineering of Pagecord users or staff
- Third-party services Pagecord depends on (report those to the vendor)

Please test against your own account and your own blog. Don't access, modify or delete anyone else's data.

## Thanks

Researchers who have reported issues responsibly:

- Yani Yuan, Beijing University of Posts and Telecommunications, September 2026: SSRF in blog exports
