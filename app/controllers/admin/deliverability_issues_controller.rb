class Admin::DeliverabilityIssuesController < AdminController
  def index
    report = DeliverabilityReport.new
    @issues = report.issues
    report.cache_count!
  rescue Postmark::InvalidApiKeyError
    @issues = []
    @error = "Postmark API token is missing or invalid. Set POSTMARK_API_TOKEN in your environment."
  rescue Postmark::Error => e
    @issues = []
    @error = "Couldn't load Postmark data: #{e.message}"
  end

  def destroy
    count = EmailSubscriber.where(email: params[:email]).destroy_all.size
    redirect_to admin_deliverability_issues_path,
                notice: "Deleted #{count} #{"subscription".pluralize(count)}."
  end
end
