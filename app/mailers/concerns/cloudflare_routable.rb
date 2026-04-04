module CloudflareRoutable
  extend ActiveSupport::Concern

  included do
    after_action :route_to_cloudflare
  end

  private

    def route_to_cloudflare
      return unless ENV["CLOUDFLARE_EMAIL_API_TOKEN"].present?
      return unless @blog&.features&.include?("cloudflare_email")
      message.delivery_method(
        CloudflareEmail::DeliveryMethod,
        api_token: ENV["CLOUDFLARE_EMAIL_API_TOKEN"],
        account_id: ENV["CLOUDFLARE_ACCOUNT_ID"]
      )
    end
end
