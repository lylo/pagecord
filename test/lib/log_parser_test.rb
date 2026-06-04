require "minitest/autorun"
require_relative "../../lib/log_parser"

class LogParserTest < Minitest::Test
  def test_completed_line_exposes_performance_metrics
    entry = LogParser.parse_line(
      "2026-02-23T21:38:00+00:00 INFO [abc123] [host=joel.pagecord.com] [ip=203.0.113.1] [user_agent=Browser] " \
      "Completed 200 OK in 192ms (Views: 106.8ms | ActiveRecord: 46.7ms (30 queries, 4 cached) | GC: 6.6ms)"
    )

    assert_equal :completed, entry.line_type
    assert_equal "200 OK in 192ms", entry.detail
    assert_equal 200, entry.status
    assert_equal 192.0, entry.duration_ms
    assert_equal 106.8, entry.views_ms
    assert_equal 46.7, entry.active_record_ms
    assert_equal 30, entry.query_count
    assert_equal 4, entry.cached_query_count
    assert_equal 6.6, entry.gc_ms
  end

  def test_completed_line_without_breakdown_still_records_status_and_duration
    entry = LogParser.parse_line(
      "2026-02-23T21:38:00+00:00 INFO [abc123] [host=joel.pagecord.com] [ip=203.0.113.1] [user_agent=Browser] " \
      "Completed 204 No Content in 3ms"
    )

    assert_equal :completed, entry.line_type
    assert_equal 204, entry.status
    assert_equal 3.0, entry.duration_ms
    assert_nil entry.active_record_ms
    assert_nil entry.query_count
  end
end
