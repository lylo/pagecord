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
    scale_factor = (ENV["SCALE"] || "1").to_f

    blog = Blog.find_by(subdomain: blog_subdomain)

    if blog.nil?
      puts "⚠️  No blog found with subdomain '#{blog_subdomain}'"
      puts "💡 Specify a blog: rake analytics:generate_sample_data BLOG=your_subdomain"
      exit 1
    end

    puts "🚀 Generating sample page view data for #{blog.display_name}..."
    puts "📏 Scale factor: #{scale_factor}x" if scale_factor != 1.0

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
    start_date = 1.year.ago.to_date
    end_date = Date.current

    # Get actual post slugs from the blog
    post_paths = blog.posts.published.map { |post| "/#{post.slug}" }

    if post_paths.empty?
      puts "⚠️  No posts found for #{blog.display_name}"
      puts "💡 Make sure the blog has some posts before generating analytics data"
      exit 1
    end

    # Common static pages + actual post paths
    static_paths = [ "/", "/about", "/contact" ]

    puts "📄 Found #{post_paths.count} posts to generate analytics for"
    puts "📅 Generating data from #{start_date.strftime('%B %d, %Y')} to #{end_date.strftime('%B %d, %Y')}"

    # Generate pool of realistic returning visitors
    visitor_pool = []
    returning_visitor_count = (50 * scale_factor).to_i
    (1..returning_visitor_count).each do |i|
      visitor_pool << "visitor_#{SecureRandom.hex(6)}"
    end
    puts "👥 Created pool of #{visitor_pool.size} potential returning visitors"

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

      # Only generate unique views now (no total vs unique distinction)
      unique_views = (rand(base_traffic) * seasonal_multiplier * scale_factor).round

      # Track unique visitors for this day
      daily_visitors = Set.new

      # Create unique page views throughout the day
      (1..unique_views).each do |i|
        # Determine visitor - 60% chance of returning visitor from pool
        visitor_hash = if rand < 0.6 && visitor_pool.any?
          visitor_pool.sample
        else
          "new_visitor_#{date}_#{SecureRandom.hex(4)}"
        end

        # Skip if we've already seen this visitor today (enforce uniqueness)
        next if daily_visitors.include?(visitor_hash)
        daily_visitors.add(visitor_hash)

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

        # Generate realistic referrers with weighted distribution
        referrer_options = [
          { url: nil, weight: 35 },  # Direct traffic (most common)
          { url: "https://www.google.com/search?q=blog", weight: 25 },
          { url: "https://x.com/user/status/123", weight: 10 },
          { url: "https://news.ycombinator.com/item?id=123", weight: 8 },
          { url: "https://www.reddit.com/r/programming", weight: 7 },
          { url: "https://www.linkedin.com/feed", weight: 5 },
          { url: "https://www.google.co.uk/search?q=blog", weight: 3 },
          { url: "https://duckduckgo.com/?q=blog", weight: 2 },
          { url: "https://bsky.app/profile/user", weight: 2 },
          { url: "https://github.com/user/repo", weight: 2 },
          { url: "https://www.bing.com/search?q=blog", weight: 1 }
        ]
        weighted_referrers = referrer_options.flat_map { |r| [ r[:url] ] * r[:weight] }
        selected_referrer = weighted_referrers.sample

        # Generate country codes with realistic distribution (weighted toward US/UK/DE)
        country_options = [
          { code: "US", weight: 40 },
          { code: "GB", weight: 15 },
          { code: "DE", weight: 10 },
          { code: "CA", weight: 8 },
          { code: "FR", weight: 5 },
          { code: "AU", weight: 5 },
          { code: "NL", weight: 4 },
          { code: "SE", weight: 3 },
          { code: "JP", weight: 3 },
          { code: "IN", weight: 3 },
          { code: "BR", weight: 2 },
          { code: "ES", weight: 2 }
        ]
        weighted_countries = country_options.flat_map { |c| [ c[:code] ] * c[:weight] }
        selected_country = weighted_countries.sample

        # Extract referrer domain
        referrer_domain = Referrer.new(selected_referrer).domain

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
          visitor_hash: visitor_hash,
          user_agent: "Mozilla/5.0 (#{[ 'Windows NT 10.0', 'Macintosh', 'X11; Linux x86_64' ].sample}) Seed Browser",
          referrer: selected_referrer,
          referrer_domain: referrer_domain,
          country: selected_country,
          is_unique: true,
          viewed_at: view_time
        )

        created_count += 1
      end

      print "." if date.day == 1  # Progress indicator monthly
    end

    total_views = blog.page_views.count

    puts "\n✅ Generated #{created_count} new page views"
    puts "📊 Blog now has #{total_views} unique page views"
    puts "📅 Data spans: #{start_date.strftime('%B %d, %Y')} to #{end_date.strftime('%B %d, %Y')}"

    # Optional rollup generation
    if ENV["ROLLUP"] == "true"
      puts "📈 Running rollup job to generate historical data..."
      begin
        cutoff_date = Date.current.prev_month.beginning_of_month.beginning_of_day
        puts "⏰ Using cutoff date: #{cutoff_date}"
        deleted_count = RollupAndCleanupPageViewsJob.perform_now
        puts "✨ Rolled up and cleaned #{deleted_count} historical page views"
      rescue => e
        puts "⚠️  Rollup job failed: #{e.message}"
        puts "💡 You may need to run it manually: RollupAndCleanupPageViewsJob.perform_now"
      end
    else
      puts "💡 To generate rollups, add ROLLUP=true flag"
      puts "   Example: rake analytics:generate_sample_data BLOG=joel ROLLUP=true"
    end

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
