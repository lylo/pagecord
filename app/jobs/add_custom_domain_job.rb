class AddCustomDomainJob < ApplicationJob
  queue_as :default

  def perform(user_id, domain)
    return unless Rails.env.production?

    user = User.find(user_id)
    Rails.logger.info "Adding custom domain #{domain} for user #{user.username}"
    HatchboxDomainApi.new(user).add_domain(domain)
  end
end