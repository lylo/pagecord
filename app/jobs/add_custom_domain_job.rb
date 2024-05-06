class AddCustomDomainJob < ApplicationJob
  queue_as :default

  def perform(user_id, domain)
    user = User.find(user_id)

    domain_changes_in_the_past_year = user.custom_domain_changes.where("created_at > ?", 1.year.ago).count

    if domain_changes_in_the_past_year >= 5
      raise "Domain change limit exceeded for user #{user.username}"
    else
      Rails.logger.info "Adding custom domain #{domain} for user #{user.username}"

      if Rails.env.production?
        HatchboxDomainApi.new(user).add_domain(domain)
      end
    end
  end
end
