require "httparty"

class CleanTalk
  include HTTParty
  base_uri "https://moderate.cleantalk.org"
  default_timeout 5

  class NoVerdict < StandardError; end

  def self.check_message(email:, nickname:, message:, page_url: nil)
    body = {
      method_name: "check_message",
      auth_key: ENV["CLEANTALK_AUTH_KEY"],
      sender_email: email,
      sender_nickname: nickname,
      message: message
    }

    # Comments deliberately collect no email address, so score on nickname and
    # message alone rather than sending a blank sender.
    body.delete(:sender_email) if email.blank?

    if page_url
      body[:sender_info] = { page_url: page_url, REFERRER: page_url }.to_json
    end

    request(body)
  end

  def self.check_newuser(email:, ip:, user_agent:, referrer:)
    body = {
      method_name: "check_newuser",
      auth_key: ENV["CLEANTALK_AUTH_KEY"],
      sender_email: email,
      sender_ip: ip,
      sender_info: { REFFERRER: referrer, USER_AGENT: user_agent }.to_json
    }

    response = request(body, timeout: 2)
    raise NoVerdict unless response["account_status"] == 1

    response
  end

  def self.request(body, **options)
    response = post("/api2.0", body: body.to_json, headers: { "Content-Type" => "application/json" }, **options)

    JSON.parse(response.body)
  end
  private_class_method :request
end
