module AppHelper
  def show_upgrade_banner?
    !cookies[:upgrade_banner_dismissed].present?
  end

  def is_current_path?(path)
    request.path.include?(path) || controller_name =~ /#{path}/
  end

  def nav_class_for(path)
    if is_current_path?(path)
      "text-slate-900 dark:text-slate-100 font-semibold"
    else
      ""
    end
  end

  def callout(type = :info, &block)
    styles = {
      info: "bg-sky-50 dark:bg-sky-900/20 border-sky-100 dark:border-sky-900/50 text-sky-800 dark:text-sky-200",
      warning: "bg-yellow-50 dark:bg-yellow-900/20 border-yellow-200 dark:border-yellow-800 text-yellow-800 dark:text-yellow-200"
    }

    content_tag :div, class: "rounded-lg border p-4 text-sm #{styles[type]}", &block
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
    attribute = attribute.to_s
    was_method = "#{attribute}_was"

    if model.respond_to?(was_method)
      model.send(was_method) || model.send(attribute)
    else
      model.send(attribute)
    end
  end
end
