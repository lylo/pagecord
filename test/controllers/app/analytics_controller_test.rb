require "test_helper"

class App::AnalyticsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:vivian)
    login_as @user
  end

  test "should get index" do
    get app_analytics_path
    assert_response :success
  end

  test "should get index with day view" do
    get app_analytics_path(view_type: "day", date: "2024-01-01")
    assert_response :success
  end

  test "should get index with month view" do
    get app_analytics_path(view_type: "month", date: "2024-01")
    assert_response :success
  end

  test "should get index with year view" do
    get app_analytics_path(view_type: "year", date: "2024")
    assert_response :success
  end

  test "analytics respect user timezone for date boundaries" do
    # Set user timezone to Eastern Time (UTC-5)
    @user.update!(timezone: "America/New_York")
    
    # Create page views around midnight boundary
    # At 11:30 PM EST (4:30 AM UTC next day)
    est_time = Time.zone.parse("2024-01-01 23:30:00").in_time_zone("America/New_York")
    utc_time = est_time.utc
    
    travel_to utc_time do
      # Create a page view at this time (4:30 AM UTC = 11:30 PM EST previous day)
      PageView.create!(
        blog: @user.blog,
        visitor_hash: "test_timezone_visitor",
        ip_address: "127.0.0.1",
        user_agent: "Test Browser",
        path: "/timezone-test",
        is_unique: true,
        viewed_at: Time.current
      )
      
      # Analytics should show this view on 2024-01-01 (EST date) not 2024-01-02 (UTC date)
      get app_analytics_path(view_type: "day", date: "2024-01-01")
      assert_response :success
      
      # The view should appear in analytics data for EST date
      assigns_data = assigns(:analytics_data)
      assert assigns_data[:total_page_views] > 0, "Should show page views for EST date boundary"
    end
  end

  test "analytics default to current date in user timezone" do
    # Set user timezone to Pacific Time (UTC-8) 
    @user.update!(timezone: "America/Los_Angeles")
    
    # At 1 AM UTC (which is 5 PM Pacific previous day)
    utc_time = Time.zone.parse("2024-01-15 01:00:00")
    
    travel_to utc_time do
      # Default analytics should show 2024-01-14 (Pacific date) not 2024-01-15 (UTC date)
      get app_analytics_path(view_type: "day")
      assert_response :success
      
      # Check that the assigned date is in Pacific timezone
      assigned_date = assigns(:date)
      pacific_date = Time.now.in_time_zone("America/Los_Angeles").to_date
      assert_equal pacific_date, assigned_date
    end
  end

  test "analytics work correctly across timezone boundaries" do
    # Set user to Tokyo timezone (UTC+9)
    @user.update!(timezone: "Asia/Tokyo")
    blog = @user.blog
    
    # Create page views at different UTC times that span Tokyo midnight
    travel_to Time.zone.parse("2024-06-15 14:30:00") do # 11:30 PM Tokyo time
      PageView.create!(
        blog: blog,
        visitor_hash: "tokyo_visitor_1", 
        ip_address: "192.168.1.1",
        user_agent: "Tokyo Browser",
        path: "/tokyo-test",
        is_unique: true,
        viewed_at: Time.current
      )
    end
    
    travel_to Time.zone.parse("2024-06-15 15:30:00") do # 12:30 AM Tokyo time (next day)
      PageView.create!(
        blog: blog,
        visitor_hash: "tokyo_visitor_2",
        ip_address: "192.168.1.2", 
        user_agent: "Tokyo Browser",
        path: "/tokyo-test",
        is_unique: true,
        viewed_at: Time.current
      )
      
      # Request analytics for June 15th Tokyo time
      get app_analytics_path(view_type: "day", date: "2024-06-15")
      assert_response :success
      
      # Should only show the first page view (11:30 PM Tokyo on June 15th)
      analytics_data = assigns(:analytics_data)
      assert_equal 1, analytics_data[:total_page_views]
      assert_equal 1, analytics_data[:unique_page_views]
      
      # Request analytics for June 16th Tokyo time  
      get app_analytics_path(view_type: "day", date: "2024-06-16")
      assert_response :success
      
      # Should show the second page view (12:30 AM Tokyo on June 16th)
      analytics_data = assigns(:analytics_data)
      assert_equal 1, analytics_data[:total_page_views]
      assert_equal 1, analytics_data[:unique_page_views]
    end
  end

  test "analytics fallback to UTC when user timezone is UTC" do
    # Set user timezone to UTC explicitly
    @user.update!(timezone: "UTC")
    
    travel_to Time.zone.parse("2024-03-10 12:00:00") do
      get app_analytics_path(view_type: "day")
      assert_response :success
      
      # Should use UTC date
      assigned_date = assigns(:date)
      utc_date = Time.now.utc.to_date
      assert_equal utc_date, assigned_date
    end
  end
end
