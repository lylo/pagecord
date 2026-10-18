class Mcp::Tools::GetDesignGuide < Mcp::Tool
  CSS_VARIABLES = {
    "--theme-bg" => "Background colour. Built-in themes and custom_theme_bg_light/dark set it",
    "--theme-text" => "Text colour. Set by the theme or custom_theme_text_light/dark",
    "--theme-accent" => "Link and accent colour. Set by the theme or custom_theme_accent_light/dark",
    "--color-bg" => "Page background, from --theme-bg",
    "--color-bg-subtle" => "Faint fill: code blocks, table headers, tags and forms",
    "--color-bg-elevated" => "Hover fill for tags and some buttons",
    "--color-bg-sunken" => "Strongest fill",
    "--color-text" => "Body text",
    "--color-text-heading" => "Headings",
    "--color-text-muted" => "Dates, captions and secondary text",
    "--color-text-light" => "Quieter text, and placeholders",
    "--color-accent" => "Links",
    "--color-accent-hover" => "Links on hover",
    "--color-border" => "Hairlines, hr and input borders",
    "--color-border-strong" => "Stronger borders",
    "--color-button-bg" => "Button fill",
    "--color-button-text" => "Button text",
    "--font-body" => "The body font, set by the .font-sans, .font-serif or .font-mono class on body",
    "--font-sans" => "Inter, on :root",
    "--font-serif" => "Lora, on :root",
    "--font-mono" => "IBM Plex Mono, on :root",
    "--font-size-base" => "Root font size, 100% by default, on :root. 112.5% makes 16px text 18px",
    "--content-width-narrow" => "28rem, on :root",
    "--content-width-standard" => "36rem, on :root",
    "--content-width-wide" => "48rem, on :root"
  }.freeze

  GUIDE = {
    workflow: [
      "Call get_custom_code first and keep its output, so the current design can be restored",
      "Read the real markup with get_page_markup for home, a post and a page before writing selectors",
      "Check CSS with update_custom_code and dry_run: true; an error names each rejected property, at-rule or value and its line",
      "preview_custom_css gives a link that shows unsaved CSS on the blog for ten minutes"
    ],
    cascade: "Custom CSS is a <style> in the head after every stylesheet get_page_markup lists, so a rule with the same " \
      "specificity as Pagecord's wins without !important. The --theme-* and --color-* variables are declared on " \
      "[data-theme], which is the body element, so override them on [data-theme] rather than :root, where they would be " \
      "shadowed. --font-*, --font-size-base and --content-width-* live on :root.",
    dark_mode: "Dark mode follows the reader's system setting through @media (prefers-color-scheme: dark). There is no " \
      "toggle, class or data attribute for it. Each built-in theme redefines --theme-bg, --theme-text and --theme-accent " \
      "inside that media query and the --color-* variables are mixed from those, so overriding the three --theme-* " \
      "variables recolours everything. Write dark overrides inside the same media query, and check both schemes.",
    custom_theme: "With theme \"custom\", custom_theme_bg_light, custom_theme_text_light and custom_theme_accent_light become " \
      "--theme-bg, --theme-text and --theme-accent, and the _dark fields the same inside prefers-color-scheme: dark.",
    body_attributes: "body carries data-theme (the theme name), data-page-type (index, home-page, page or post), " \
      "data-slug on a single post or page, and a font class: font-sans, font-serif or font-mono. .blog carries the " \
      "width class (max-w-content-narrow, -standard or -wide) and the page type.",
    css_rules: {
      allowed_at_rules: %w[ @media @supports @container @layer @keyframes @import @font-face @page ],
      font_imports: "@import must come first and may only load https URLs from #{Css::Sanitizer::ALLOWED_FONT_HOSTS.to_sentence}. " \
        "Subscribers can instead add a <link> to custom_head_html. @font-face can't set src, so self-hosted fonts aren't possible",
      urls: "url() accepts http, https and relative URLs only",
      not_supported: [ "Nested rules, including &", "@property", "expression()", "</style" ],
      properties: "Most standard properties are allowed, including grid, flex, place-*, inset, aspect-ratio, scrollbar-*, " \
        "logical properties and custom properties. Use dry_run to check anything unusual"
    },
    footer_html: {
      placement: "Rendered inside footer.blog-footer > div.custom-footer, at the end of .blog on every page, above the Pagecord logo (a#brand) when branding shows",
      allowed_tags: Blog::CustomFooter::ALLOWED_TAGS,
      allowed_attributes: Blog::CustomFooter::ALLOWED_ATTRIBUTES
    },
    design_rules: [
      "Wrap :hover transforms and other hover effects in @media (hover: hover) and (pointer: fine), so they don't stick on touch screens",
      "Keep the nav on one line on phones; check at 375px wide",
      "Put animation and transitions inside @media (prefers-reduced-motion: no-preference), or turn them off in reduce",
      "Check light and dark mode, and keep text contrast at WCAG AA or better",
      "Prefer the CSS variables to hard-coded colours, so dark mode keeps working",
      "Use logical properties such as margin-inline-start, so right-to-left blogs work"
    ],
    docs: [ "https://help.pagecord.com/custom-css", "https://help.pagecord.com/custom-footer" ]
  }.freeze

  describe "Get the reference for designing a Pagecord blog: the CSS variables, how dark mode and the custom theme map to them, " \
    "how custom CSS cascades, what custom CSS and footer HTML may contain, and design rules to follow. Read it before writing CSS.",
    read_only: true

  def self.perform(blog)
    GUIDE.merge(css_variables: CSS_VARIABLES)
  end
end
