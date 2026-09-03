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

  def font_stylesheet
    case font_class
    when "font-sans"
      "inter"
    when "font-serif"
      "lora"
    when "font-mono"
      "ibm-plex-mono"
    else
      "inter" # Default to sans font
    end
  end

  def font_preload_links
    # Preload upright faces only, the rest load on demand via the stylesheet
    case font_class
    when "font-serif"
      preload_fonts([
        "lora/Lora-VariableFont_wght.woff2"
      ])
    when "font-mono"
      preload_fonts([
        "ibm-plex-mono/IBMPlexMono-Regular.woff2",
        "ibm-plex-mono/IBMPlexMono-Bold.woff2"
      ])
    else
      preload_fonts([
        "inter/InterVariable.woff2"
      ])
    end
  end

  def preload_fonts(paths)
    safe_join(paths.map { |path|
      tag.link(rel: "preload",
              href: asset_path(path),
              as: "font",
              type: "font/woff2",
              crossorigin: "anonymous") + "\n"
    })
  end


  def theme_data_attribute
    return nil unless @blog

    "data-theme=\"#{@blog.theme}\"".html_safe
  end
end
