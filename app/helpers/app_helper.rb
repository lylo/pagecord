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
end
