class MarketingAutomation::DeleteContactJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    if user = User.find(user_id)
      unsubscribe_from_pagecord_blog(user)
    end
  end

  private

    def unsubscribe_from_pagecord_blog(user)
      if pagecord = Blog.find_by(name: "pagecord")
        pagecord.email_subscribers.find_by(email: user.email)&.destroy
      end
    end
end
