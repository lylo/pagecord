namespace :analytics do
  desc "Generate sample page view data for development and testing"
  task generate_sample_data: :environment do
    # Safety check: prevent running in production
    if Rails.env.production?
      puts "🚫 This task cannot be run in production environment!"
      puts "💡 Sample data generation is only allowed in development and test environments"
      exit 1
    end

    blog_subdomain = ENV["BLOG"] || "joel"

    blog = Blog.find_by(subdomain: blog_subdomain)

    if blog.nil?
      puts "⚠️  No blog found with subdomain '#{blog_subdomain}'"
      puts "💡 Specify a blog: rake analytics:generate_sample_data BLOG=your_subdomain"
      exit 1
    end

    puts "🚀 Generating sample page view data for #{blog.display_name}..."

    # Clear existing page views for clean slate
    existing_count = blog.page_views.count
    if existing_count > 0
      print "⚠️  Found #{existing_count} existing page views. Clear them? (y/N): "
      response = STDIN.gets.chomp.downcase
      if response == "y" || response == "yes"
        blog.page_views.delete_all
        puts "🗑️  Cleared existing page views"
      else
        puts "📊 Adding to existing data..."
      end
    end

    # Generate data for the past year
    start_date = 1.month.ago.to_date
    end_date = Date.current

    # Get actual post slugs from the blog
    post_paths = blog.posts.map { |post| "/#{post.slug}" }

    if post_paths.empty?
      puts "⚠️  No posts found for #{blog.display_name}"
      puts "💡 Make sure the blog has some posts before generating analytics data"
      exit 1
    end

    # Common static pages + actual post paths
    static_paths = [ "/", "/about", "/contact" ]

    puts "📄 Found #{post_paths.count} posts to generate analytics for"
    puts "📅 Generating data from #{start_date.strftime('%B %d, %Y')} to #{end_date.strftime('%B %d, %Y')}"

    created_count = 0

    # Generate page views for each day
    (start_date..end_date).each do |date|
      # Vary traffic by day of week and month
      base_traffic = case date.wday
      when 1..5 then 15..45  # Weekdays
      when 6 then 8..25      # Saturday
      when 0 then 5..20      # Sunday
      end

      # Add some seasonal variation
      seasonal_multiplier = case date.month
      when 1, 2, 7, 8 then 0.7      # Lower traffic in Jan/Feb/Jul/Aug
      when 3, 4, 9, 10 then 1.2     # Higher in spring/fall
      else 1.0                      # Normal for other months
      end

      total_views = (rand(base_traffic) * seasonal_multiplier).round
      unique_views = [ (total_views * 0.7).round, total_views ].min

      # Create page views throughout the day
      (1..total_views).each do |i|
        is_unique = i <= unique_views

        # Random time throughout the day (business hours weighted)
        if rand < 0.7  # 70% during business hours
          hour = rand(9..17)
        else
          hour = rand(0..23)
        end
        minute = rand(0..59)

        view_time = date.beginning_of_day + hour.hours + minute.minutes

        # Weight paths realistically (homepage gets more traffic)
        selected_path = if rand < 0.4
          "/"  # 40% homepage
        elsif rand < 0.8 && post_paths.any?
          post_paths.sample  # 40% actual blog posts
        else
          static_paths.sample  # 20% other static pages
        end

        # Generate realistic referrers
        referrers = [
          nil,  # Direct traffic
          "https://www.google.com",
          "https://twitter.com",
          "https://news.ycombinator.com",
          "https://reddit.com",
          "https://linkedin.com"
        ]

        countries = [ "US", "CA", "UK", "DE", "FR", "AU", "JP", "NL" ]

        # Find the corresponding post if it's a post path
        post = nil
        if selected_path != "/" && !static_paths.include?(selected_path)
          slug = selected_path.gsub("/", "")
          post = blog.posts.find_by(slug: slug)
        end

        PageView.create!(
          blog: blog,
          post: post,
          path: selected_path,
          visitor_hash: "seed_#{date}_#{i}_#{SecureRandom.hex(4)}",
          ip_address: "192.168.#{rand(1..255)}.#{rand(1..254)}",
          user_agent: "Mozilla/5.0 (#{[ 'Windows NT 10.0', 'Macintosh', 'X11; Linux x86_64' ].sample}) Seed Browser",
          referrer: referrers.sample,
          country: countries.sample,
          is_unique: is_unique,
          viewed_at: view_time
        )

        created_count += 1
      end

      print "." if date.day == 1  # Progress indicator monthly
    end

    total_views = blog.page_views.count
    unique_views = blog.page_views.where(is_unique: true).count

    puts "\n✅ Generated #{created_count} new page views"
    puts "📊 Blog now has #{total_views} total page views (#{unique_views} unique)"
    puts "📅 Data spans: #{start_date.strftime('%B %d, %Y')} to #{end_date.strftime('%B %d, %Y')}"
    puts "🎯 View your analytics at /app/analytics"
  end

  desc "Clear all page view data for a blog"
  task clear_data: :environment do
    # Safety check: prevent running in production
    if Rails.env.production?
      puts "🚫 This task cannot be run in production environment!"
      puts "💡 Data clearing is only allowed in development and test environments"
      exit 1
    end

    blog_subdomain = ENV["BLOG"] || "joel"

    blog = Blog.find_by(subdomain: blog_subdomain)

    if blog.nil?
      puts "⚠️  No blog found with subdomain '#{blog_subdomain}'"
      exit 1
    end

    count = blog.page_views.count
    if count == 0
      puts "📊 No page view data found for #{blog.display_name}"
      exit 0
    end

    print "⚠️  Delete #{count} page views for #{blog.display_name}? (y/N): "
    response = STDIN.gets.chomp.downcase

    if response == "y" || response == "yes"
      blog.page_views.delete_all
      puts "🗑️  Cleared all page view data for #{blog.display_name}"
    else
      puts "🚫 Operation cancelled"
    end
  end
end
