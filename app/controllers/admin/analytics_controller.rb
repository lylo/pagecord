class Admin::AnalyticsController < Admin::BaseController
  def index
    @report = Analytics::AdminReport.new(params[:view_type], params[:date])
  end
end
