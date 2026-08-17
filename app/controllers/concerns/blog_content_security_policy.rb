# Blog pages carry customer custom code, so a host allowlist can't work here.
# This policy is a floor, not a fence: any https source is fine, while data:,
# javascript: and plain-http vectors and <base> injection stay blocked.
# Enforced, unlike the app-side policy, which is still report-only.
#
# The app-side previews (drafts, theme garden) render the same blog content,
# embeds included, so they apply the same policy to the preview actions.
module BlogContentSecurityPolicy
  extend ActiveSupport::Concern

  class_methods do
    def blog_content_security_policy(**options)
      content_security_policy(**options) do |policy|
        policy.default_src :self, :https
        policy.script_src  :self, :https, :unsafe_inline
        policy.style_src   :self, :https, :unsafe_inline
        policy.frame_src   :self, :https
        policy.img_src     :self, :https, :data, :blob
        policy.object_src  :none
        policy.base_uri    :self
        policy.form_action :self, :https
      end
      content_security_policy_report_only false, **options
    end
  end
end
