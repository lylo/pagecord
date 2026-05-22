namespace :theme_templates do
  desc "Generate screenshots for active theme templates. Set OVERWRITE=true to regenerate existing."
  task :screenshots, [ :blog_url ] => :environment do |_t, args|
    require "selenium-webdriver"

    abort "Usage: rake \"theme_templates:screenshots[http://joel.localhost:3000]\"" unless args[:blog_url]

    templates = ThemeTemplate.active.ordered
    abort "No active templates found" if templates.empty?

    blog_url = args[:blog_url].chomp("/")
    blog = Blog.find_by!(subdomain: URI.parse(blog_url).host.split(".").first)
    output_dir = Rails.root.join("app/assets/images/theme_templates")

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless=new")
    options.add_argument("--window-size=1280,800")
    options.add_argument("--force-device-scale-factor=1")
    options.add_argument("--hide-scrollbars")

    have_cwebp = system("which cwebp > /dev/null 2>&1")
    abort "cwebp not found — install with: brew install webp" unless have_cwebp

    driver = Selenium::WebDriver.for(:chrome, options: options)
    overwrite = ENV["OVERWRITE"] == "true"

    begin
      templates.each do |template|
        slug = template.name.parameterize
        webp_path = output_dir.join("#{slug}.webp")

        if webp_path.exist? && !overwrite
          puts "#{template.name}... skipped (exists, set OVERWRITE=true to regenerate)"
          next
        end

        print "#{template.name}... "

        screenshot_attrs = { width: "standard" }.merge(template.appearance_attributes)
        original_attrs = blog.attributes.slice(*screenshot_attrs.keys.map(&:to_s))
        blog.update_columns(screenshot_attrs.stringify_keys)

        begin
          driver.navigate.to("#{blog_url}?t=#{Time.now.to_i}")
          sleep 2

          png_path = output_dir.join("#{slug}.png")
          driver.save_screenshot(png_path.to_s)

          system("cwebp", "-q", "80", "-resize", "640", "0", png_path.to_s, "-o", webp_path.to_s, out: File::NULL, err: File::NULL)
          File.delete(png_path)
          puts "done"
        ensure
          blog.update_columns(original_attrs)
        end
      end
    ensure
      driver.quit
    end

    puts "\nScreenshots saved to #{output_dir}"
  end
end
