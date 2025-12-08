# frozen_string_literal: true

require "net/http"
require "openssl"

# Fix for OpenSSL 3.6.0 CRL verification failures
# OpenSSL 3.x enables CRL checking by default, which fails for many CDNs/APIs.
# This disables CRL checking in development only.

if Rails.env.development?
  module NetHTTPSSLFix
    def start
      if use_ssl?
        self.cert_store ||= begin
          store = OpenSSL::X509::Store.new
          store.set_default_paths
          store.flags = 0 # Disable CRL checking
          store
        end
      end
      super
    end
  end

  Net::HTTP.prepend(NetHTTPSSLFix)
end
