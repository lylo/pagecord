require "minitest/autorun"
require "tmpdir"
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

  def test_rack_attack_throttle_line_is_a_throttled_request
    entry = LogParser.parse_line(
      "2026-09-02T03:20:26+00:00 WARN [abc123] [host=joel.pagecord.com] [ip=203.0.113.1] [user_agent=Browser] " \
      "[Rack::Attack] Throttled POST /login from 203.0.113.1"
    )

    assert_equal :throttled, entry.line_type
    assert_equal "POST /login", entry.detail
    assert_equal 429, entry.status
    assert_nil entry.duration_ms
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

  def test_recent_dated_files_counts_days_not_files
    names = %w[
      production.log.2026-10-23.gz
      production.log.2026-10-24T005202.gz
      production.log.2026-10-24T154837.gz
      production.log.2026-10-25T000703.gz
    ]

    Dir.mktmpdir do |dir|
      Dir.mkdir(File.join(dir, "log"))
      names.each { FileUtils.touch(File.join(dir, "log", it)) }

      Dir.chdir(dir) do
        assert_equal names.last(3), LogParser.recent_dated_files(2).map { File.basename(it) }
      end
    end
  end
end
