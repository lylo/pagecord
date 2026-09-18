module AppHelper
  NAV_SECTIONS = %w[ posts pages comments analytics settings ].freeze

  def show_upgrade_banner?
    !cookies[:upgrade_banner_dismissed].present?
  end

  def pill(text, **options)
    tag.span text, **options, class: [ "rounded-full bg-slate-200 px-2 py-0.5 text-xs font-medium text-slate-600 dark:bg-slate-700 dark:text-slate-300", options[:class] ]
  end

  def is_current_path?(section)
    # /app/posts/:token/comments contains two section names, so the controller wins.
    return controller_name == section if NAV_SECTIONS.include?(controller_name)

    request.path.include?(section) || controller_name.include?(section)
  end

  def nav_link_attributes(section)
    {
      class: "flex w-full items-center whitespace-nowrap px-4 py-2 font-medium hover:bg-slate-100 dark:hover:bg-slate-800 aria-[current=page]:bg-slate-100 aria-[current=page]:text-slate-900 dark:aria-[current=page]:bg-slate-800 dark:aria-[current=page]:text-slate-100 md:w-auto md:rounded-full md:px-3.5 md:py-1.5 md:hover:bg-transparent md:hover:text-slate-900 md:dark:hover:bg-transparent md:dark:hover:text-slate-100 md:aria-[current=page]:bg-slate-800 md:aria-[current=page]:text-white md:dark:aria-[current=page]:bg-slate-100 md:dark:aria-[current=page]:text-slate-900",
      aria: { current: ("page" if is_current_path?(section)) }
    }
  end

  def callout(type = :info, &block)
    styles = {
      info: "bg-sky-50 dark:bg-sky-900/20 border-sky-100 dark:border-sky-900/50 text-sky-800 dark:text-sky-200",
      warning: "bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800 text-amber-800 dark:text-amber-200"
    }

    content_tag :div, class: "rounded-lg border p-4 text-sm #{styles[type]}", &block
  end

  # The breadcrumb belongs to the first sheet on the page, whichever that turns out to be.
  def settings_breadcrumb
    return if @settings_breadcrumb_rendered

    @settings_breadcrumb_rendered = true
    content_for(:settings_breadcrumb)
  end

  def settings_section(title = nil, description: nil, control: nil, &block)
    render layout: "app/settings/section", locals: { title: title, description: description, control: control }, &block
  end

  def settings_row(title, hint: nil, stacked: false, **options, &block)
    render layout: "app/settings/row", locals: { title: title, hint: hint, stacked: stacked, options: options }, &block
  end

  def trial_callout(feature_name)
    return unless Current.user.on_trial?

    callout(:info) do
      "#{feature_name} is a premium feature. ".html_safe +
        link_to("Subscribe", app_settings_subscriptions_path, class: "underline font-medium") +
        " to keep access after your trial ends.".html_safe
    end
  end

  # Returns the persisted value for a model attribute, falling back to the current value
  # if no persisted value exists. This is useful in forms where you want to show the
  # database value rather than the invalid submitted value when validation fails.
  #
  # @param model [ActiveRecord::Base] The model instance
  # @param attribute [Symbol, String] The attribute name
  # @return [Object] The persisted value or current value
  #
  # Example:
  #   # In a form where @blog.subdomain validation failed
  #   persisted_value(@blog, :subdomain) # Returns the database value, not the invalid input
  def persisted_value(model, attribute)
    model.attribute_was(attribute)
  end
end
