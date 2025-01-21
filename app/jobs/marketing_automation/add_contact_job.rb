require "loops_sdk"

class MarketingAutomation::AddContactJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    return unless Rails.env.production?

    user = User.find(user_id)

    add_to_loops(user) if user
  end

  private

    # https://loops.so
    def add_to_loops(user)
      LoopsSdk::Contacts.create(
        email: user.email,
        properties: {
          username: user.blog.name,
          deliveryEmail: user.blog.delivery_email
        },
        mailing_lists: {
          cm3bk30v201in0ml49wza278w: user.marketing_consent
        })
    rescue LoopsSdk::APIError => e
      # 409: Contact already exists. This can happen if someone had previously signed up to the
      #      mailing list via the website, so ignore this error.
      raise e unless e.status == 409
    end
end
