module Admin::DeliverabilityHelper
  def deliverability_count
    @deliverability_count ||= DeliverabilityReport.cached_count.to_i
  end
end
