require "test_helper"

class Analytics::BaseTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
    @analytics = Analytics::Base.new(@blog)
  end

  test "cutoff_time returns 1900 when no rollups exist" do
    assert_equal 0, Rollup.count
    cutoff = @analytics.send(:cutoff_time)
    assert_equal Date.new(1900, 1, 1), cutoff
  end

  test "cutoff_time returns previous month start when rollups exist" do
    Rollup.create!(name: "test", time: 1.month.ago, interval: "day", value: 1.0, dimensions: {})

    travel_to Date.new(2025, 9, 15) do
      cutoff = @analytics.send(:cutoff_time)
      expected = Date.new(2025, 8, 1).beginning_of_day
      assert_equal expected, cutoff
    end
  end
end
