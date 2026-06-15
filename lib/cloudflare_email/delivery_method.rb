require "net/http"
require "json"

module CloudflareEmail
  class DeliveryError < StandardError; end

  class DeliveryMethod
    DEFAULT_OPEN_TIMEOUT = 5
    DEFAULT_READ_TIMEOUT = 10

    attr_accessor :settings

    def initialize(settings)
      validate_settings(settings)
      @settings = settings
    end

    def deliver!(mail)
      uri = URI("https://api.cloudflare.com/client/v4/accounts/#{settings[:account_id]}/email/sending/send_raw")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = settings.fetch(:open_timeout, DEFAULT_OPEN_TIMEOUT)
      http.read_timeout = settings.fetch(:read_timeout, DEFAULT_READ_TIMEOUT)

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{settings[:api_token]}"
      request["Accept"] = "application/json"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload(mail))

      result = JSON.parse(http.request(request).body)
      raise DeliveryError, error_message(result) unless result["success"]
    end

    private

      def validate_settings(settings)
        raise ArgumentError, "Cloudflare account_id is required" if settings[:account_id].to_s.empty?
        raise ArgumentError, "Cloudflare api_token is required" if settings[:api_token].to_s.empty?
      end

      def error_message(result)
        errors = result["errors"]
        return "Unknown Cloudflare delivery error" unless errors.is_a?(Array) && errors.any?

        errors.map { |error| error.is_a?(Hash) ? error["message"] : error.to_s }.compact.join(", ")
      end

      def payload(mail)
        {
          from: mail.from.first,
          recipients: [ mail.to, mail.cc, mail.bcc ].compact.flatten.uniq,
          mime_message: mail.encoded
        }
      end
  end
end
