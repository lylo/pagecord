require "httparty"

class IpReputation
  class ApiVoid
    include HTTParty

    base_uri ENV["IP_REPUTATION_ENDPOINT"]
    default_timeout 2

    def self.valid?(ip)
      return true if Rails.env.production? && !ENV["IP_REPUTATION_API_KEY"] && !ENV["IP_REPUTATION_ENDPOINT"]

      response = get("/", query: {
        key: ENV["IP_REPUTATION_API_KEY"],
        ip: ip
      })

      json = JSON.parse(response.body)
      if json["error"]
        Rails.logger.error "IP Reputation API error: #{json['error']}"
        return true
      end

      return true unless json["success"]

      # Call class methods
      valid_ip?(json) && valid_country?(json)
    rescue HTTParty::Error, JSON::ParserError, Net::ReadTimeout, Net::OpenTimeout, Timeout::Error => e
      Rails.logger.error "IP Reputation check failed for #{ip}: #{e.message}"
      true
    end

    private

    BLOCKED_COUNTRIES = %w[CN RU].freeze

    def self.valid_ip?(json) # Changed to self.valid_ip?
      engines = json.dig("data", "report", "blacklists", "engines")
      return true unless engines

      engines.values.count { |engine| engine["detected"] } < 2
    end

    def self.valid_country?(json) # Changed to self.valid_country?
      country_code = json.dig("data", "report", "information", "country_code")
      return false unless country_code

      Rails.logger.info "IP reputation country code: #{country_code}"

      !BLOCKED_COUNTRIES.include?(country_code)
    end
  end
end
