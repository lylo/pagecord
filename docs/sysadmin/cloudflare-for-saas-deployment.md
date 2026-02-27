# Cloudflare for SaaS — Deployment Checklist

Migrating custom domains from Caddy/Hatchbox to Cloudflare for SaaS. Both paths coexist during migration:

- DNS → `proxy.pagecord.com` → Caddy handles TLS (existing)
- DNS → `domains.pagecord.com` → Cloudflare handles TLS (new, with edge caching)

---

## Phase A: Set up Cloudflare for SaaS (no user impact)

1. **Cloudflare dashboard:**
   - Enable Cloudflare for SaaS on the zone
   - Create `domains.pagecord.com` A record → origin IP (proxied)
   - Set `domains.pagecord.com` as the fallback origin for Custom Hostnames

2. **Expand API token permissions:**
   - Add `Zone > SSL and Certificates > Edit` to `CLOUDFLARE_API_TOKEN`

3. **Deploy:**
   - DB migration (`cloudflare_custom_hostname_id` column)
   - `CloudflareSaasApi` class

## Phase B: Start registering domains (no user impact)

4. **Remove `ON_DEMAND_TLS` env var** from Hatchbox, then deploy job changes (swap to `CloudflareSaasApi`)

5. **Run migration task:**
   ```bash
   bin/rails cloudflare:migrate_domains
   ```
   This registers all existing custom domains as Cloudflare Custom Hostnames. Safe to run while Caddy is active — doesn't affect routing.

6. **Deploy** status UI in settings

7. **Verify:**
   ```ruby
   blog = Blog.find_by(custom_domain: "example.com")
   CloudflareSaasApi.new(blog).status
   # Should show hostname registered, SSL status will be pending until DNS switches
   ```

## Phase C: Gradual DNS migration

8. Help guide now recommends `domains.pagecord.com` — new users get these instructions automatically

9. Optionally email existing custom domain users asking them to update their DNS CNAME from `proxy.pagecord.com` to `domains.pagecord.com`

10. **Verify** after a user switches DNS:
    ```bash
    curl -sI https://their-domain.com/ | grep -i cf-cache-status
    # Should show cf-cache-status header
    ```

## Phase D: Decommission Caddy (once all users migrated)

11. Delete:
    - `app/models/hatchbox_domain_api.rb`
    - `app/controllers/custom_domains_controller.rb`
    - `test/controllers/custom_domains_controller_test.rb`
    - `verify_domain` route in `config/routes.rb`

12. Remove env vars: `HATCHBOX_API_KEY`, `HATCHBOX_API_ENDPOINT`

13. Clean up `.env.example`
