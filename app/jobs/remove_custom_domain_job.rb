class RemoveCustomDomainJob < ApplicationJob
  queue_as :default

  def perform(user_id, domain)
    user = User.find(user_id)

    Rails.logger.info "Removing custom domain #{domain} for user #{user.username}"

    if Rails.env.production?
      HatchboxDomainApi.new(user).remove_domain(domain)
    end
  end
end
