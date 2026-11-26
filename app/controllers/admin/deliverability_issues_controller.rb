class Admin::DeliverabilityIssuesController < Admin::BaseController
  def index
    report = DeliverabilityReport.new
    @issues = report.issues
    report.cache_count!
    @health = report.health
  rescue *DeliverabilityReport::SES_ERRORS => e
    @issues ||= []
    @error = "Couldn't load SES data: #{e.message}"
  end

  def destroy
    count = EmailSubscriber.where("lower(email) = ?", params[:email].downcase).destroy_all.size
    redirect_to admin_deliverability_issues_path,
                notice: "Deleted #{count} #{"subscription".pluralize(count)}."
  end
end
