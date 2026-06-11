require "net/http"
require "json"

module CloudflareEmail
  class DeliveryError < StandardError; end

  class DeliveryMethod
    attr_accessor :settings

    def initialize(settings)
      @settings = settings
    end

    def deliver!(mail)
      uri = URI("https://api.cloudflare.com/client/v4/accounts/#{settings[:account_id]}/email/sending/send_raw")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri, "Authorization" => "Bearer #{settings[:api_token]}", "Content-Type" => "application/json")
      request.body = payload(mail).to_json

      result = JSON.parse(http.request(request).body)
      raise DeliveryError, result["errors"].map { |e| e["message"] }.join(", ") unless result["success"]
    end

    private

    def payload(mail)
      {
        from: mail.from.first,
        recipients: [ mail.to, mail.cc, mail.bcc ].compact.flatten.uniq,
        mime_message: mail.encoded
      }
    end
  end
end
