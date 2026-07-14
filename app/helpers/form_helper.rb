module FormHelper
  def field_error(model, field)
    content_tag :div, model.errors.full_messages_for(field).first, class: "field-error"
  end

  def styled_text_field(form, field, options = {})
    final_class = [ "form-field", options[:class] ].compact.join(" ")
    form.text_field field, options.merge(class: final_class)
  end

  def styled_check_box(form, field, options = {})
    final_class = [ "form-checkbox h-5 w-5 rounded border-slate-300 text-slate-600 focus:ring focus:ring-slate-300 focus:ring-offset-0 disabled:cursor-not-allowed dark:border-slate-600 dark:bg-slate-700 dark:focus:ring-slate-600", options[:class] ].compact.join(" ")
    form.check_box field, options.merge(class: final_class)
  end
end
