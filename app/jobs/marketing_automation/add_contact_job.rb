class MarketingAutomation::AddContactJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    if user = User.find(user_id)
      subscribe_to_pagecord_blog(user)
    end
  end

  private

    def subscribe_to_pagecord_blog(user)
      if user.marketing_consent
        if pagecord = Blog.find_by(subdomain: "blog")
          pagecord.email_subscribers.find_or_create_by(email: user.email) do |subscriber|
            subscriber.confirmed_at = Time.current
          end
        end
      end
    end
end
