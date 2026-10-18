module Blog::ApiKey
  extend ActiveSupport::Concern

  def generate_api_key!
    token = SecureRandom.hex(16)
    update!(api_key_digest: Digest::SHA256.hexdigest(token), api_key_hint: token.last(4))
    token
  end

  def revoke_api_key!
    update!(api_key_digest: nil, api_key_hint: nil)
  end

  def api_key?
    api_key_digest.present?
  end

  class_methods do
    def find_by_api_key(token)
      kept.with_kept_user.find_by(api_key_digest: Digest::SHA256.hexdigest(token))
    end

    def find_by_mcp_token(token)
      find_by_api_key(token) || McpConnection.find_by_token(token)&.blog
    end
  end
end
