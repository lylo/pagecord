module Admin::BadgesHelper
  BADGE_TONES = {
    danger: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
    warning: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400",
    info: "bg-sky-100 text-sky-700 dark:bg-sky-900/30 dark:text-sky-400",
    success: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400"
  }.freeze

  def badge(text, tone = nil, **options)
    return pill(text, **options) unless tone

    tag.span text, **options, class: [ "rounded-full px-2 py-0.5 text-xs font-medium", BADGE_TONES.fetch(tone), options[:class] ]
  end
end
