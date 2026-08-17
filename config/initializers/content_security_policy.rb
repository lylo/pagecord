# config/initializers/content_security_policy.rb
#
# This is the app-side policy (dashboard, settings, admin, marketing).
# Public blog pages get a permissive policy instead, because custom code means
# readers can be served any https script or iframe. The app-side previews
# render blog content too, so they share it – see BlogContentSecurityPolicy.

Rails.application.configure do
  config.content_security_policy do |policy|
    # Base policy
    policy.default_src :self

    # A rogue <base> tag would rewrite every relative URL on the page
    policy.base_uri :self

    # Fonts
    policy.font_src :self, :https, :data

    # Images
    policy.img_src :self, :data, :blob, :https,
                   "http://localhost:3000",
                   "http://lvh.me:3000",
                   "https://storage.pagecord.com"

    # Object embeds – block entirely
    policy.object_src :none

    # Scripts
    policy.script_src :self, :https,
                      "https://challenges.cloudflare.com",
                      "https://static.cloudflareinsights.com",
                      "https://plausible.io",
                      "https://paddle.com",
                      "*.paddle.com",
                      :unsafe_inline

    # Styles
    policy.style_src :self, :https,
                     "https://challenges.cloudflare.com",
                     :unsafe_inline

    # Frames and embeds
    policy.frame_src :self,
                     "https://challenges.cloudflare.com",
                     "https://paddle.com",
                     "*.paddle.com"

    # Native media
    policy.media_src :self, :https

    # Connect sources
    policy.connect_src :self, :https,
                       "https://plausible.io",
                       "https://cloudflareinsights.com",
                       "https://static.cloudflareinsights.com",
                       "https://paddle.com",
                       "*.paddle.com"

    policy.manifest_src :self, :https,
                        "https://d2rvfk326kpipd.cloudfront.net"

    # Optional: CSP violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Optional: better nonce generator if needed later
  # (not used here because unsafe_inline is enabled)
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }

  # Don't apply nonce directives because unsafe_inline is used
  config.content_security_policy_nonce_directives = []

  # Enable CSP enforcement
  # For debugging: set to true for report-only mode first
  config.content_security_policy_report_only = true
end
