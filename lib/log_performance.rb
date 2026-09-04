module LogPerformance
  THROTTLED_ENDPOINT = "Rack::Attack (throttled before Rails)"

  # One record per request id. A request that raises after rendering, or that
  # is rate limited, logs a second "Completed" line when the error page renders
  # under the same id; only the first line describes the request itself.
  #
  # Requests Rack::Attack answers with 429 before Rails runs never log
  # "Completed"; they come back as records with throttled: true and no timings.
  def self.records_for(entries, host: nil)
    requests = {}
    records = []

    entries.each do |e|
      next if e.uuid.to_s.empty?

      request = requests[e.uuid] ||= {
        timestamp: e.timestamp,
        host: e.host,
        ip: e.ip,
        user_agent: e.user_agent
      }

      case e.line_type
      when :started
        request[:timestamp] = e.timestamp
        request[:host] = e.host
        request[:path] = e.detail
      when :processing
        request[:endpoint] = e.detail
      when :throttled
        next if host && e.host != host

        records << request.merge(path: e.detail, status: 429, endpoint: THROTTLED_ENDPOINT, throttled: true)
      when :completed
        next if request[:completed]

        request[:completed] = true
        request[:host] ||= e.host
        next if host && request[:host] != host

        records << request.merge(
          status: e.status,
          duration_ms: e.duration_ms,
          views_ms: e.views_ms,
          active_record_ms: e.active_record_ms,
          query_count: e.query_count,
          cached_query_count: e.cached_query_count,
          gc_ms: e.gc_ms
        )
      end
    end

    records
  end

  def self.status_counts(records)
    records.group_by { |record| record[:status] }.transform_values(&:size).sort_by { |status, count| [ -count, status ] }
  end

  def self.endpoint_stats(records)
    records.group_by { |record| record[:endpoint] || "(unknown)" }.map do |endpoint, endpoint_records|
      durations = endpoint_records.map { |record| record[:duration_ms] }.compact
      active_record_times = endpoint_records.map { |record| record[:active_record_ms] }.compact
      query_counts = endpoint_records.map { |record| record[:query_count] }.compact

      {
        endpoint: endpoint,
        count: endpoint_records.size,
        average_ms: average(durations),
        p95_ms: percentile(durations, 95),
        max_ms: durations.max,
        active_record_average_ms: average(active_record_times),
        query_average: average(query_counts),
        query_max: query_counts.max
      }
    end
  end

  def self.average(values)
    return nil if values.empty?

    values.sum.to_f / values.size
  end

  def self.percentile(values, percentile)
    return nil if values.empty?

    sorted = values.sort
    sorted[((percentile / 100.0) * (sorted.size - 1)).ceil]
  end
end
