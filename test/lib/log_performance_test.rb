require "minitest/autorun"
require_relative "../../lib/log_parser"
require_relative "../../lib/log_performance"

class LogPerformanceTest < Minitest::Test
  def test_records_for_pairs_request_lines_by_request_id
    entries = [
      entry(:started, uuid: "abc", host: "joel.pagecord.com", detail: "GET /posts"),
      entry(:processing, uuid: "abc", host: "joel.pagecord.com", detail: "Blogs::PostsController#index"),
      entry(:completed, uuid: "abc", host: "joel.pagecord.com", status: 200, duration_ms: 120.0, active_record_ms: 30.0, query_count: 12)
    ]

    records = LogPerformance.records_for(entries)

    assert_equal 1, records.size
    assert_equal "joel.pagecord.com", records.first[:host]
    assert_equal "GET /posts", records.first[:path]
    assert_equal "Blogs::PostsController#index", records.first[:endpoint]
    assert_equal 120.0, records.first[:duration_ms]
    assert_equal 12, records.first[:query_count]
  end

  def test_records_for_filters_by_host
    entries = [
      entry(:started, uuid: "abc", host: "joel.pagecord.com", detail: "GET /posts"),
      entry(:completed, uuid: "abc", host: "joel.pagecord.com", status: 200, duration_ms: 120.0),
      entry(:started, uuid: "def", host: "other.pagecord.com", detail: "GET /"),
      entry(:completed, uuid: "def", host: "other.pagecord.com", status: 200, duration_ms: 80.0)
    ]

    records = LogPerformance.records_for(entries, host: "other.pagecord.com")

    assert_equal 1, records.size
    assert_equal "other.pagecord.com", records.first[:host]
    assert_equal 80.0, records.first[:duration_ms]
  end

  def test_records_for_counts_a_request_once_when_the_error_page_logs_a_second_completed_line
    entries = [
      entry(:started, uuid: "abc", host: "joel.pagecord.com", detail: "GET /verify_domain"),
      entry(:processing, uuid: "abc", host: "joel.pagecord.com", detail: "CustomDomains::VerificationsController#show"),
      entry(:completed, uuid: "abc", host: "joel.pagecord.com", status: 429, duration_ms: 5.0),
      entry(:processing, uuid: "abc", host: "joel.pagecord.com", detail: "ErrorsController#too_many_requests"),
      entry(:completed, uuid: "abc", host: "joel.pagecord.com", status: 429, duration_ms: 9.0)
    ]

    records = LogPerformance.records_for(entries)

    assert_equal 1, records.size
    assert_equal 429, records.first[:status]
    assert_equal 5.0, records.first[:duration_ms]
    assert_equal "CustomDomains::VerificationsController#show", records.first[:endpoint]
  end

  def test_records_for_includes_rack_attack_throttles_as_throttled_records
    entries = [
      entry(:throttled, uuid: "abc", host: "joel.pagecord.com", ip: "203.0.113.1", detail: "POST /login", status: 429),
      entry(:started, uuid: "def", host: "joel.pagecord.com", detail: "GET /"),
      entry(:completed, uuid: "def", host: "joel.pagecord.com", status: 200, duration_ms: 80.0)
    ]

    throttles, records = LogPerformance.records_for(entries).partition { |record| record[:throttled] }

    assert_equal 1, records.size
    assert_equal 1, throttles.size
    assert_equal "POST /login", throttles.first[:path]
    assert_equal 429, throttles.first[:status]
    assert_equal LogPerformance::THROTTLED_ENDPOINT, throttles.first[:endpoint]
    assert_nil throttles.first[:duration_ms]
  end

  def test_status_counts_orders_by_frequency
    records = [ { status: 200 }, { status: 404 }, { status: 200 }, { status: 429 } ]

    assert_equal [ [ 200, 2 ], [ 404, 1 ], [ 429, 1 ] ], LogPerformance.status_counts(records)
  end

  def test_endpoint_stats_calculates_averages_and_percentiles
    records = [
      { endpoint: "Blogs::PostsController#index", duration_ms: 100.0, active_record_ms: 10.0, query_count: 4 },
      { endpoint: "Blogs::PostsController#index", duration_ms: 200.0, active_record_ms: 20.0, query_count: 8 },
      { endpoint: "Blogs::PostsController#index", duration_ms: 300.0, active_record_ms: 30.0, query_count: 12 }
    ]

    stats = LogPerformance.endpoint_stats(records).first

    assert_equal "Blogs::PostsController#index", stats[:endpoint]
    assert_equal 3, stats[:count]
    assert_equal 200.0, stats[:average_ms]
    assert_equal 300.0, stats[:p95_ms]
    assert_equal 20.0, stats[:active_record_average_ms]
    assert_equal 8.0, stats[:query_average]
    assert_equal 12, stats[:query_max]
  end

  private

    def entry(line_type, **attributes)
      LogParser::Entry.new(
        timestamp: Time.utc(2026, 2, 23, 21, 38),
        line_type: line_type,
        **attributes
      )
    end
end
