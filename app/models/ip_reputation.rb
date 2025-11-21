class IpReputation
  # Defines the interface for IP reputation providers.
  # Providers should implement a `self.valid?(ip)` method.
  #
  # Available providers:
  # - IpReputation::ApiVoid
  # - IpReputation::GetIpIntel
  #
  # The default provider is GetIpIntel.
  # To change the provider, set `IpReputation.provider`.
  #
  # Example:
  #   IpReputation.provider = IpReputation::ApiVoid
  #
  class << self
    attr_writer :provider

    def provider
      @provider ||= IpReputation::GetIpIntel
    end

    def valid?(ip)
      provider.valid?(ip)
    end
  end
end
