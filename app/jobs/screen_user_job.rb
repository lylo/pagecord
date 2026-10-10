class ScreenUserJob < ApplicationJob
  queue_as :default

  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 5

  def perform(user_id, ip:, user_agent:)
    User.find(user_id).screen(ip: ip, user_agent: user_agent)
  end
end
