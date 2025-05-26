module AppHelper
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

  # Returns the persisted value for a model attribute, falling back to the current value
  # if no persisted value exists. This is useful in forms where you want to show the
  # database value rather than the invalid submitted value when validation fails.
  #
  # @param model [ActiveRecord::Base] The model instance
  # @param attribute [Symbol, String] The attribute name
  # @return [Object] The persisted value or current value
  #
  # Example:
  #   # In a form where @blog.name validation failed
  #   persisted_value(@blog, :name) # Returns the database value, not the invalid input
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
