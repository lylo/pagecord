class Oauth::Client
  LOOPBACK_HOSTS = %w[ localhost 127.0.0.1 ].freeze

  attr_reader :name, :redirect_uris

  def self.register(name:, redirect_uris:)
    verifier.generate({ name:, redirect_uris: })
  end

  def self.find(client_id)
    attributes = verifier.verified(client_id.to_s)
    new(**attributes.symbolize_keys) if attributes
  end

  def self.redirect_uri_acceptable?(uri)
    uri = URI.parse(uri.to_s)
    uri.scheme == "https" || (uri.scheme == "http" && LOOPBACK_HOSTS.include?(uri.host))
  rescue URI::InvalidURIError
    false
  end

  def self.verifier
    Rails.application.message_verifier(:oauth_client)
  end
  private_class_method :verifier

  def initialize(name:, redirect_uris:)
    @name = name
    @redirect_uris = redirect_uris
  end

  def redirect_uri_allowed?(uri)
    redirect_uris.map { without_loopback_port(it) }.include?(without_loopback_port(uri))
  end

  private

    def without_loopback_port(uri)
      URI.parse(uri.to_s).tap { it.port = nil if LOOPBACK_HOSTS.include?(it.host) }.to_s
    rescue URI::InvalidURIError
      nil
    end
end
