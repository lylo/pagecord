# Rack 3 honours RFC 7239 `Forwarded` ahead of `X-Forwarded-For` by default.
# We sit behind Cloudflare → Caddy, neither of which currently sanitises an
# inbound `Forwarded` header, and the cloudflare-rails gem only configures
# trusted-proxy handling for the X-Forwarded-* chain. Pin Rack to that chain
# so a spoofed `Forwarded: for=127.0.0.1` cannot influence req.ip.
# See AGENTS.md "Client IP" gotcha and the 2026-05-01 incident.
Rack::Request.forwarded_priority = [ :x_forwarded ]
