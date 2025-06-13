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
    case font_class
    when "font-sans"
      preload_fonts([
        "inter/InterVariable.woff2",
        "inter/InterVariable-Italic.woff2"
      ])
    when "font-serif"
      preload_fonts([
        "lora/Lora-VariableFont_wght.woff2",
        "lora/Lora-Italic-VariableFont_wght.woff2"
      ])
    when "font-mono"
      preload_fonts([
        "ibm-plex-mono/IBMPlexMono-Thin.woff2",
        "ibm-plex-mono/IBMPlexMono-ThinItalic.woff2",
        "ibm-plex-mono/IBMPlexMono-ExtraLight.woff2",
        "ibm-plex-mono/IBMPlexMono-ExtraLightItalic.woff2",
        "ibm-plex-mono/IBMPlexMono-Light.woff2",
        "ibm-plex-mono/IBMPlexMono-LightItalic.woff2",
        "ibm-plex-mono/IBMPlexMono-Regular.woff2",
        "ibm-plex-mono/IBMPlexMono-Italic.woff2",
        "ibm-plex-mono/IBMPlexMono-Text.woff2",
        "ibm-plex-mono/IBMPlexMono-TextItalic.woff2",
        "ibm-plex-mono/IBMPlexMono-Medium.woff2",
        "ibm-plex-mono/IBMPlexMono-MediumItalic.woff2",
        "ibm-plex-mono/IBMPlexMono-SemiBold.woff2",
        "ibm-plex-mono/IBMPlexMono-SemiBoldItalic.woff2",
        "ibm-plex-mono/IBMPlexMono-Bold.woff2",
        "ibm-plex-mono/IBMPlexMono-BoldItalic.woff2"
      ])
    else
      preload_fonts([
        "inter/InterVariable.woff2",
        "inter/InterVariable-Italic.woff2"
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
