class PlausibleEventJob < ApplicationJob
  queue_as :default

  def perform(name, url:, user_agent:, ip:)
    return unless Rails.env.production?

    HTTParty.post(
      "https://plausible.io/api/event",
      headers: {
        "User-Agent" => user_agent,
        "X-Forwarded-For" => ip,
        "Content-Type" => "application/json"
      },
      body: { name:, url:, domain: "pagecord.com" }.to_json
    )
  end
end
