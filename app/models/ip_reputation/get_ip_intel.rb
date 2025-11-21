require "httparty"

class IpReputation
  class GetIpIntel
    include HTTParty

    # The GetIpIntel API blocks certain IPs and returns a non-zero value.
    # We'll treat this as a failed request and allow the IP.
    # For example, local IPs will be blocked.
    # http://check.getipintel.net/check.php?ip=127.0.0.1&contact=someuser@somedomain.com
    # returns "Your IP 127.0.0.1 has been blocked from using this service."
    def self.valid?(ip)
      response = HTTParty.get("http://check.getipintel.net/check.php", query: {
        ip: ip,
        contact: "hello@pagecord.com", # Hardcoded contact email
        flags: "b" # Blocked IP check
      }, timeout: 2)

      # A value of "1" means it's a bad IP.
      # A value of "0" means it's a good IP.
      # A value between 0 and 1 is a probability.
      # We will consider anything >= 0.99 as a bad IP.
      # An error will return a non-numeric value, so we will treat that as a good IP.
      # We don't want to block users if the API is down.
      # The to_f will convert non-numeric values to 0.0, which is a good IP.
      response.body.to_f >= 0.99 ? false : true

    rescue HTTParty::Error, Net::ReadTimeout, Net::OpenTimeout, Timeout::Error => e
      Rails.logger.error "GetIpIntel check failed for #{ip}: #{e.message}"
      true # Always default to valid
    end
  end
end
