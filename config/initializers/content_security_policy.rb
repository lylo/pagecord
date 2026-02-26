# config/initializers/content_security_policy.rb

Rails.application.configure do
  config.content_security_policy do |policy|
    # Base policy
    policy.default_src :self

    # Fonts
    policy.font_src :self, :https, :data

    # Images
    policy.img_src :self, :data, :https,
                   "http://localhost:3000",
                   "http://lvh.me:3000",
                   "https://storage.pagecord.com",
                   "https://githubusercontent.com",
                   "https://github.githubassets.com"

    # Object embeds – block entirely
    policy.object_src :none

    # Scripts
    policy.script_src :self, :https,
                      "https://challenges.cloudflare.com",
                      "https://static.cloudflareinsights.com",
                      "https://strava-embeds.com",
                      "https://gist.github.com",
                      "https://github.githubassets.com",
                      "https://assets-cdn.github.com",
                      "https://githubusercontent.com",
                      "https://plausible.io",
                      "https://paddle.com",
                      "*.paddle.com",
                      :unsafe_inline

    # Styles
    policy.style_src :self, :https,
                     "https://gist.github.com",
                     "https://github.githubassets.com",
                     "https://assets-cdn.github.com",
                     "https://challenges.cloudflare.com",
                     :unsafe_inline

    # Frames and embeds
    policy.frame_src :self,
                     "https://challenges.cloudflare.com",
                     "https://open.spotify.com",
                     "https://player.vimeo.com",
                     "https://www.youtube.com",
                     "https://youtube.com",
                     "https://embed.music.apple.com",
                     "https://gist.github.com",
                     "https://bandcamp.com",
                     "*.bandcamp.com",
                     "https://strava-embeds.com",
                     "https://share.transistor.fm",
                     "https://paddle.com",
                     "*.paddle.com"

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
