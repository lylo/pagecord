# The editor previews media embeds, and an embed is a third-party iframe, so the
# editing actions need the frame-src the blog itself has. Only that one directive:
# handing these pages BlogContentSecurityPolicy would also open script-src, which
# they have no reason to want.
module EditorContentSecurityPolicy
  extend ActiveSupport::Concern

  class_methods do
    def editor_content_security_policy(**options)
      content_security_policy(**options) do |policy|
        policy.frame_src :self, :https
      end
    end
  end
end
