require "application_system_test_case"

# Every Theme Garden design, and Classic, rendered on the same blog and compared
# with the computed CSS recorded in test/system/design_snapshots/. A change to
# blogs.css or the blog's markup that reaches a design shows up here. Computed
# values rather than pixels, so the snapshots hold on any machine.
#
# After an intended change: DESIGN_SNAPSHOTS=record bin/rails test test/system/design_snapshots_test.rb
class DesignSnapshotsTest < ApplicationSystemTestCase
  SNAPSHOTS = Rails.root.join("test/system/design_snapshots")

  # Links whose text is their own address become embeds after the page loads,
  # so they are left out rather than raced
  ELEMENTS = [
    "body", "main", ".blog",
    "header", "header nav", "header nav a", "header nav a.social-link", "header nav svg",
    ".titlebar", ".avatar-container", ".avatar", ".avatar img", ".blog-title", ".blog-title a",
    ".bio", ".bio p", ".bio a", "header hr",
    ".email-subscriber-form", ".email-form-container", ".subscription-description", ".form-fieldset", ".email-input", ".email-subscriber-form input[type=submit]",
    "article", "article .post-title", "article .post-title a", "article .post-body", ".post-body p", ".post-body a", ".post-body h2", ".post-body blockquote", ".post-body ul", ".post-body li", ".post-body img",
    "article footer", "article footer a", ".post-actions", ".tags-container", ".tag-link",
    ".stream_layout", ".title_layout", ".cards_layout", ".post-stream-item", ".posts-titles", ".year-header", ".post-row", ".post-row time", ".post-row a",
    ".post-card", ".post-card-link", ".post-card-content", ".post-card-title", ".post-card-meta", ".post-card-image img",
    "footer.blog-footer", ".custom-footer", "#brand", "#brand svg"
  ].freeze

  PROPERTIES = %w[
    display position top right bottom left z-index float visibility opacity overflow-x overflow-y
    box-sizing max-width min-width max-height
    margin-top margin-right margin-bottom margin-left padding-top padding-right padding-bottom padding-left
    border-top-width border-top-style border-top-color border-right-width border-right-style border-right-color
    border-bottom-width border-bottom-style border-bottom-color border-left-width border-left-style border-left-color
    border-top-left-radius border-top-right-radius border-bottom-right-radius border-bottom-left-radius
    flex-direction flex-wrap justify-content align-items align-self flex-grow flex-shrink flex-basis order
    row-gap column-gap grid-template-columns grid-template-rows grid-column grid-row
    color background-color background-image box-shadow outline-style
    font-family font-size font-weight font-style line-height letter-spacing
    text-align text-transform text-decoration-line text-decoration-color text-underline-offset white-space text-wrap
    list-style-type object-fit aspect-ratio filter transform
  ].freeze

  # Values left out of a snapshot because they are what an element has when
  # nothing sets them; a change to or from one still shows as a difference
  DEFAULTS = {
    "position" => "static", "top" => "auto", "right" => "auto", "bottom" => "auto", "left" => "auto", "z-index" => "auto",
    "float" => "none", "visibility" => "visible", "opacity" => "1", "overflow-x" => "visible", "overflow-y" => "visible",
    "box-sizing" => "border-box", "max-width" => "none", "min-width" => "auto", "max-height" => "none",
    "margin-top" => "0px", "margin-right" => "0px", "margin-bottom" => "0px", "margin-left" => "0px",
    "padding-top" => "0px", "padding-right" => "0px", "padding-bottom" => "0px", "padding-left" => "0px",
    "border-top-style" => "none", "border-right-style" => "none", "border-bottom-style" => "none", "border-left-style" => "none",
    "border-top-left-radius" => "0px", "border-top-right-radius" => "0px", "border-bottom-right-radius" => "0px", "border-bottom-left-radius" => "0px",
    "flex-direction" => "row", "flex-wrap" => "nowrap", "justify-content" => "normal", "align-items" => "normal", "align-self" => "auto",
    "flex-grow" => "0", "flex-shrink" => "1", "flex-basis" => "auto", "order" => "0", "row-gap" => "normal", "column-gap" => "normal",
    "grid-template-columns" => "none", "grid-template-rows" => "none", "grid-column" => "auto", "grid-row" => "auto",
    "background-color" => "rgba(0, 0, 0, 0)", "background-image" => "none", "box-shadow" => "none", "outline-style" => "none",
    "font-weight" => "400", "font-style" => "normal", "letter-spacing" => "normal", "text-align" => "start", "text-transform" => "none",
    "text-decoration-line" => "none", "text-underline-offset" => "auto", "white-space" => "normal", "text-wrap" => "wrap",
    "list-style-type" => "disc", "object-fit" => "fill", "aspect-ratio" => "auto", "filter" => "none", "transform" => "none"
  }.freeze

  RENDERS = {
    "home desktop light" => { width: 1280, dark: false, view: :home },
    "home desktop dark" => { width: 1280, dark: true, view: :home },
    "home phone light" => { width: 390, dark: false, view: :home },
    "post desktop light" => { width: 1280, dark: false, view: :post }
  }.freeze

  setup do
    @blog = blogs(:joel)
    @blog.avatar.attach(io: file_fixture("avatar.png").open, filename: "avatar.png", content_type: "image/png")
    @blog.update!(bio: "<p>Writing about <strong>photography</strong> and <a href=\"https://example.com\">elsewhere</a>.</p>")
    use_subdomain(@blog.subdomain)
  end

  [ "classic", *YAML.load_file(Rails.root.join("test/fixtures/theme_templates.yml")).values.map { it["slug"] } ].each do |slug|
    test "#{slug} renders as recorded" do
      @blog.apply_design(slug == "classic" ? nil : ThemeTemplate.find_by!(slug:))

      snapshot = RENDERS.to_h { |name, render| [ name, computed_styles(**render) ] }
      path = SNAPSHOTS.join("#{slug}.json")

      if ENV["DESIGN_SNAPSHOTS"] == "record"
        SNAPSHOTS.mkpath
        path.write(JSON.pretty_generate(snapshot) + "\n")
      else
        assert path.exist?, "No snapshot for #{slug}: run DESIGN_SNAPSHOTS=record bin/rails test #{__FILE__}"
        assert_snapshot JSON.parse(path.read), snapshot, slug
      end
    end
  end

  private

    def computed_styles(width:, dark:, view:)
      browser = Capybara.current_session.driver.browser
      browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height: 1000, deviceScaleFactor: 1, mobile: false)
      browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-color-scheme", value: dark ? "dark" : "light" } ])
      browser.execute_cdp("Emulation.setScrollbarsHidden", hidden: true)

      visit "#{view == :home ? "/" : blog_post_path(posts(:one).slug)}?render=#{SecureRandom.hex(4)}"
      page.document.synchronize do
        raise Capybara::ExpectationNotMet unless evaluate_script("document.readyState === 'complete' && window.innerWidth") == width
      end

      evaluate_script(<<~JS, ELEMENTS, PROPERTIES, DEFAULTS)
        ((selectors, properties, defaults) => {
          const result = {}
          selectors.forEach(selector => {
            const embeddable = element => element.matches("a") && element.textContent.trim() === element.getAttribute("href")
            Array.from(document.querySelectorAll(selector)).filter(element => !embeddable(element)).slice(0, 2).forEach((element, index) => {
              const style = element.computedStyleMap()
              const value = property => (style.get(property)?.toString() ?? getComputedStyle(element).getPropertyValue(property)).replace(/BlinkMacSystemFont|"system-ui"/g, "system-ui")
              const unset = property => {
                const side = property.match(/^border-(top|right|bottom|left)-(width|color)$/)
                if (side) return value(`border-${side[1]}-style`) === "none"
                if (property === "text-decoration-color") return value("text-decoration-line") === "none"
                return defaults[property] === value(property)
              }
              result[`${selector} #${index + 1}`] = properties.filter(property => !unset(property)).map(property => `${property}: ${value(property)}`).join("; ")
            })
          })
          return result
        })(arguments[0], arguments[1], arguments[2])
      JS
    end

    def assert_snapshot(expected, actual, slug)
      differences = expected.keys.union(actual.keys).flat_map do |render|
        expected_elements = expected[render] || {}
        actual_elements = actual[render] || {}

        expected_elements.keys.union(actual_elements.keys).flat_map do |element|
          was = expected_elements[element]
          now = actual_elements[element]
          next [ "#{render}: #{element} #{was ? "no longer rendered" : "newly rendered"}" ] unless was && now

          was, now = [ was, now ].map { it.split("; ").to_h { it.split(": ", 2) } }
          was.keys.union(now.keys).reject { was[it] == now[it] }.map { "#{render}: #{element} #{it}: #{was[it] || "unset"} → #{now[it] || "unset"}" }
        end
      end

      assert differences.empty?, "#{slug} no longer renders as recorded (#{differences.size} changes):\n#{differences.first(40).join("\n")}"
    end
end
