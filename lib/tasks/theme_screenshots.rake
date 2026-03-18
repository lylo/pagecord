namespace :theme_templates do
  desc "Generate screenshots for all active theme templates. Pass the URL of a blog with content."
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

    driver = Selenium::WebDriver.for(:chrome, options: options)

    templates.each do |template|
      print "#{template.name}... "

      original_attrs = blog.attributes.slice(*template.appearance_attributes.keys.map(&:to_s))
      blog.update_columns(template.appearance_attributes.stringify_keys)

      driver.navigate.to(blog_url)
      sleep 2

      png_path = output_dir.join("#{template.name.parameterize}.png")
      webp_path = output_dir.join("#{template.name.parameterize}.webp")

      driver.save_screenshot(png_path.to_s)
      blog.update_columns(original_attrs)

      if system("which cwebp > /dev/null 2>&1")
        system("cwebp -q 80 -resize 640 0 #{png_path} -o #{webp_path} > /dev/null 2>&1")
        File.delete(png_path)
      else
        puts "warning: cwebp not found, keeping PNG"
        next
      end

      puts "done"
    end

    driver.quit
    puts "\nScreenshots saved to #{output_dir}"
  end
end
