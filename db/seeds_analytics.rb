# Sample analytics data for testing
# Run with: rails runner db/seeds_analytics.rb

puts "Creating sample analytics data..."

# Find the first blog or create one
blog = Blog.first
if blog.nil?
  puts "No blog found. Please create a user and blog first."
  exit
end

puts "Adding page views for blog: #{blog.display_name}"

# Create sample page views for the last 30 days
(30.days.ago.to_date..Date.current).each do |date|
  # Random number of page views per day (0-50)
  total_views = rand(0..50)
  unique_views = [total_views, rand(0..30)].min
  
  # Create page views throughout the day
  (1..total_views).each do |i|
    is_unique = i <= unique_views
    random_hour = rand(0..23)
    random_minute = rand(0..59)
    view_time = date.beginning_of_day + random_hour.hours + random_minute.minutes
    
    # Random paths
    paths = ["/", "/about", "/contact", "/blog-post-1", "/blog-post-2", "/services", "/portfolio"]
    random_path = paths.sample
    
    PageView.create!(
      blog: blog,
      path: random_path,
      visitor_hash: "sample_#{date}_#{i}",
      ip_address: "192.168.1.#{rand(1..254)}",
      user_agent: "Sample User Agent #{i}",
      referrer: ["https://google.com", "https://twitter.com", nil].sample,
      country: ["US", "CA", "UK", "DE"].sample,
      is_unique: is_unique,
      viewed_at: view_time
    )
  end
  
  print "."
end

puts "\nCreated sample page views for #{blog.display_name}"
puts "Total page views: #{blog.page_views.count}"
puts "Unique page views: #{blog.page_views.where(is_unique: true).count}"
puts "\nYou can now visit /app/analytics to see the charts in action!"