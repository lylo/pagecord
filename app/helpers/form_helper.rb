module FormHelper
  def field_error(model, field)
    content_tag :div, model.errors.full_messages_for(field).first, class: "field-error"
  end

  def styled_text_field(form, field, options = {})
    final_class = ["form-field", options[:class]].compact.join(" ")
    form.text_field field, options.merge(class: final_class)
  end
end
