require "test_helper"

class App::AnalyticsHelperTest < ActionView::TestCase
  include App::AnalyticsHelper

  # Switching view keeps today in sight when the period being viewed contains it,
  # so the reader lands somewhere meaningful rather than on the 1st of the month.
  test "switching to a narrower view lands on today when the period contains it" do
    assert_equal Date.current, date_for_view(Date.current.beginning_of_month, "month", "day")
    assert_equal Date.current, date_for_view(Date.current.beginning_of_year, "year", "day")
    assert_equal Date.current.beginning_of_month, date_for_view(Date.current.beginning_of_year, "year", "month")
  end

  test "switching to a narrower view keeps the position within a past period" do
    travel_to Date.new(2026, 3, 20) do
      assert_equal Date.new(2024, 6, 20), date_for_view(Date.new(2024, 6, 1), "month", "day")
      assert_equal Date.new(2024, 3, 1), date_for_view(Date.new(2024, 1, 1), "year", "month")
      assert_equal Date.new(2024, 1, 1), date_for_view(Date.new(2024, 1, 1), "year", "day")
    end
  end

  # A shorter month has no 31st to keep the day number on.
  test "the day is clamped to the end of a shorter month" do
    travel_to Date.new(2026, 3, 31) do
      assert_equal Date.new(2024, 2, 29), date_for_view(Date.new(2024, 2, 1), "month", "day")
      assert_equal Date.new(2025, 2, 28), date_for_view(Date.new(2025, 2, 1), "month", "day")
    end
  end

  test "switching to a wider view widens to the period containing the date" do
    assert_equal Date.new(2024, 6, 1), date_for_view(Date.new(2024, 6, 14), "day", "month")
    assert_equal Date.new(2024, 1, 1), date_for_view(Date.new(2024, 6, 14), "day", "year")
    assert_equal Date.new(2024, 1, 1), date_for_view(Date.new(2024, 6, 1), "month", "year")
  end

  test "staying on the same view keeps the date" do
    %w[ day month year ].each do |view|
      assert_equal Date.new(2024, 6, 14), date_for_view(Date.new(2024, 6, 14), view, view)
    end
  end

  test "current_period? recognises the period holding today" do
    assert current_period?(Date.current, "day")
    assert current_period?(Date.current.beginning_of_month, "month")
    assert current_period?(Date.current.beginning_of_year, "year")

    assert_not current_period?(Date.current - 1.day, "day")
    assert_not current_period?(Date.current - 1.month, "month")
    assert_not current_period?(Date.current - 1.year, "year")
  end
end
