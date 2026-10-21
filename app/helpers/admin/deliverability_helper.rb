module Admin::DeliverabilityHelper
  def deliverability_count
    @deliverability_count ||= DeliverabilityReport.cached_count.to_i
  end

  def deliverability_tone(issue)
    case issue.type
    when "HardBounce", "BadEmailAddress", "SpamComplaint", "Blocked" then :danger
    when "ManualSuppression" then :warning
    else issue.actionable? ? :warning : nil
    end
  end
end
