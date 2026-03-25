ActiveSupport.on_load(:action_mailer) do
  ActionMailer::Base.add_delivery_method(
    :cloudflare_email,
    CloudflareEmail::DeliveryMethod,
    api_token: ENV["CLOUDFLARE_EMAIL_API_TOKEN"],
    account_id: ENV["CLOUDFLARE_ACCOUNT_ID"]
  )
end
