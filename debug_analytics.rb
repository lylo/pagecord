# Quick analytics debugging script
# Run with: rails runner debug_analytics.rb

puts "=== Analytics Debug ==="

blog = Blog.first
if blog.nil?
  puts "No blog found!"
  exit
end

puts "Blog: #{blog.display_name}"
puts "Total page views: #{blog.page_views.count}"
puts "Unique page views: #{blog.page_views.where(is_unique: true).count}"

puts "\n=== Recent Page Views ==="
blog.page_views.order(viewed_at: :desc).limit(10).each do |pv|
  puts "#{pv.viewed_at.strftime('%Y-%m-%d %H:%M')} - #{pv.path} - Unique: #{pv.is_unique}"
end

puts "\n=== August 2024 Data ==="
august_start = Date.new(2024, 8, 1).beginning_of_day
august_end = Date.new(2024, 8, 31).end_of_day
august_views = blog.page_views.where(viewed_at: august_start..august_end)

puts "August total views: #{august_views.count}"
puts "August unique views: #{august_views.where(is_unique: true).count}"

puts "\n=== Daily breakdown for August ==="
august_views.group("DATE(viewed_at)").group(:is_unique).count.each do |key, count|
  date, is_unique = key
  puts "#{date}: #{is_unique ? 'Unique' : 'Total'} = #{count}"
end

puts "\n=== Current Month Chart Data ==="
require_relative 'app/controllers/app/analytics_controller'

# Simulate the controller logic
current_date = Date.current.beginning_of_month
start_date = current_date.beginning_of_month
end_date = current_date.end_of_month

puts "Analyzing: #{start_date} to #{end_date}"

# Replicate the month_chart_data logic
all_days = (start_date..end_date).to_a
step_size = [all_days.length / 10, 1].max
puts "Step size: #{step_size}"

chart_points = all_days.each_slice(step_size).map do |day_group|
  representative_day = day_group[day_group.length / 2]
  group_start = day_group.first.beginning_of_day
  group_end = day_group.last.end_of_day
  page_views = blog.page_views.where(viewed_at: group_start..group_end)
  
  result = {
    date: representative_day,
    unique_visitors: page_views.where(is_unique: true).count,
    total_visitors: page_views.count,
    date_range: "#{group_start.strftime('%m/%d')} - #{group_end.strftime('%m/%d')}"
  }
  
  puts "Point: #{result[:date].strftime('%m/%d')} (#{result[:date_range]}) - U:#{result[:unique_visitors]}, T:#{result[:total_visitors]}"
  result
end

total_chart_unique = chart_points.sum { |p| p[:unique_visitors] }
total_chart_total = chart_points.sum { |p| p[:total_visitors] }

puts "\nChart totals: Unique=#{total_chart_unique}, Total=#{total_chart_total}"