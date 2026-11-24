class Admin::DeliverabilityPurgesController < Admin::BaseController
  def create
    issues = DeliverabilityReport.new.issues
    count = issues.flat_map(&:subscribers).each(&:destroy).size

    redirect_to admin_deliverability_issues_path,
                notice: "Deleted #{count} #{"subscription".pluralize(count)} " \
                        "across #{issues.size} #{"address".pluralize(issues.size)}."
  rescue *DeliverabilityReport::SES_ERRORS => e
    redirect_to admin_deliverability_issues_path, alert: "Couldn't load SES data: #{e.message}"
  end
end
