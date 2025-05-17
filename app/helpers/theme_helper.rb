module ThemeHelper
  def content_width_class
    return "max-w-content-standard" unless @blog

    case @blog.width
    when "narrow"
      "max-w-content-narrow"
    when "wide"
      "max-w-content-wide"
    else
      "max-w-content-standard"
    end
  end

  def font_class
    return "font-sans" unless @blog

    @blog.font_class
  end

  def theme_data_attribute
    return nil unless @blog

    "data-theme=\"#{@blog.theme}\"".html_safe
  end
end
