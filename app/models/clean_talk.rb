require "httparty"

class CleanTalk
  include HTTParty
  base_uri "https://moderate.cleantalk.org"
  default_timeout 5

  def self.check_message(email:, nickname:, message:)
    response = post("/api2.0", body: {
      method_name: "check_message",
      auth_key: ENV["CLEANTALK_AUTH_KEY"],
      sender_email: email,
      sender_nickname: nickname,
      message: message
    }.to_json, headers: { "Content-Type" => "application/json" })

    JSON.parse(response.body)
  end
end
