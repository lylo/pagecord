module Admin::DeliverabilityHelper
  def deliverability_count
    @deliverability_count ||= DeliverabilityReport.cached_count.to_i
  end

  def deliverability_badge_class(issue)
    case issue.type
    when "HardBounce", "BadEmailAddress" then "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400"
    when "SpamComplaint", "Blocked"      then "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400"
    when "ManualSuppression"             then "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400"
    else
      if issue.actionable?
        "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"
      else
        "bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300"
      end
    end
  end
end
