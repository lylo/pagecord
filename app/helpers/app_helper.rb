module AppHelper
  def is_current_path?(path)
    request.path.include?(path) || controller_name =~ /#{path}/
  end

  def nav_class_for(path)
    if is_current_path?(path)
      "text-black dark:text-slate-200 font-semibold"
    else
      ""
    end
  end
end
