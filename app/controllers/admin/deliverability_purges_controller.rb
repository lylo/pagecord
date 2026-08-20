class Admin::DeliverabilityPurgesController < AdminController
  def create
    emails = DeliverabilityReport.new.actionable.map(&:email)
    count = EmailSubscriber.where(email: emails).destroy_all.size

    redirect_to admin_deliverability_issues_path,
                notice: "Deleted #{count} #{"subscription".pluralize(count)} " \
                        "across #{emails.size} #{"address".pluralize(emails.size)}."
  rescue Postmark::Error => e
    redirect_to admin_deliverability_issues_path, alert: "Couldn't load Postmark data: #{e.message}"
  end
end
