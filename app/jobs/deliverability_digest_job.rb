class DeliverabilityDigestJob < ApplicationJob
  queue_as :default

  def perform
    report = DeliverabilityReport.new
    count = report.actionable.size
    report.cache_count! # before the guard, so the nav badge clears when it reaches zero

    return if count.zero?

    Rails.logger.info "[Deliverability] Sending digest: #{count} addresses need attention"
    AdminMailer.deliverability_digest(count).deliver_later
  end
end
