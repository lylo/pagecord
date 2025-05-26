# config/initializers/content_security_policy.rb

Rails.application.configure do
  config.content_security_policy do |policy|
    # Base policy
    policy.default_src :self

    # Fonts
    policy.font_src    :self, :https, :data

    # Images
    policy.img_src     :self, :https, :data

    # Object (plugin) embeds – block entirely
    policy.object_src  :none

    # Scripts
    policy.script_src  :self, :https, "https://strava-embeds.com", "https://gist.github.com", :unsafe_inline
    # unsafe_inline is needed for GitHub gist embeds to work properly

    # Styles
    policy.style_src   :self, :https, "https://gist.github.com", :unsafe_inline
    # unsafe_inline is needed for GitHub gist embeds to work properly

    # Frames and embeds
    policy.frame_src   :self,
                       "https://open.spotify.com",
                       "https://*.bandcamp.com",
                       "https://player.vimeo.com",
                       "https://www.youtube.com",
                       "https://youtube.com",
                       "https://embed.music.apple.com",
                       "https://gist.github.com"

    # Media sources (optional: if you host media elsewhere)
    # policy.media_src :self, :https

    # Connect sources (for APIs, websockets, etc.)
    policy.connect_src :self, :https, "https://plausible.io"

    # Manifest sources (for web app manifests)
    policy.manifest_src :self, :https, "https://d2rvfk326kpipd.cloudfront.net"

    # Reporting (optional)
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Nonce generation for inline scripts
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }

  # Don't apply nonce directives - we need unsafe-inline for GitHub embeds
  config.content_security_policy_nonce_directives = %w[]

  # Enable CSP enforcement
  # config.content_security_policy_report_only = false
end
