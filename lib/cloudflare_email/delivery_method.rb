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
      uri = URI("https://api.cloudflare.com/client/v4/accounts/#{settings[:account_id]}/email/sending/send")
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
        from: from_field(mail),
        to: mail.to,
        subject: mail.subject,
        html: mail.html_part&.decoded,
        text: mail.text_part&.decoded,
        reply_to: mail.reply_to&.first
      }.compact
    end

    def from_field(mail)
      addr = mail.from.first
      name = mail[:from].display_names&.first&.presence
      name ? { address: addr, name: name } : addr
    end
  end
end
