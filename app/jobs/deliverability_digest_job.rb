class DeliverabilityDigestJob < ApplicationJob
  queue_as :default

  def perform
    report = DeliverabilityReport.new
    count = report.actionable.size
    report.cache_count! # before the guard, so the nav badge clears when it reaches zero

    warning = report.health.warning
    return if count.zero? && warning.nil?

    Rails.logger.info "[Deliverability] Sending digest: #{count} addresses need attention#{", #{warning}" if warning}"
    AdminMailer.deliverability_digest(count, warning).deliver_later
  end
end
