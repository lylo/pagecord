module FormHelper
  def has_field_error?(model, field)
    model&.errors[field].present?
  end

  def field_error(model, field)
    return unless has_field_error?(model, field)

    content_tag :div, model.errors.full_messages_for(field).first, class: "text-red-500 text-xs mt-1"
  end

  def styled_text_field(form, field, options = {})
    object = form.object
    has_error = has_field_error?(object, field)

    base_classes = [
      "placeholder-slate-300 dark:placeholder-slate-600",
      "dark:bg-slate-900",
      "text-slate-800 dark:text-slate-200",
      "rounded-lg",
      "focus:outline-none focus:ring-0",
      "focus:border-slate-500 dark:focus:border-slate-400"
    ]

    border_class = has_error ? "border-red-500" : "border-slate-300 dark:border-slate-700"
    final_class = [ *base_classes, border_class, options[:class] ].compact.join(" ")

    form.text_field field, options.merge(class: final_class)
  end
end
