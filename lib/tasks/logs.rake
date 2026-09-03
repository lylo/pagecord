require_relative "../log_parser"
require_relative "../log_performance"

module LogDisplay
  unless defined?(RESET)
    RESET  = "\e[0m"
    BOLD   = "\e[1m"
    DIM    = "\e[2m"
    RED    = "\e[31m"
    GREEN  = "\e[32m"
    YELLOW = "\e[33m"
    CYAN   = "\e[36m"
    WHITE  = "\e[37m"
    BG_ROW = "\e[48;5;236m"
  end
  def self.terminal_width
    width = ENV["COLUMNS"]&.to_i
    if width.nil? || width < 40
      width = `tput cols 2>/dev/null`.strip.to_i
      width = 120 if width < 40
    end
    width
  end

  def self.truncate(str, max)
    return str if str.length <= max
    str[0, max - 1] + "\u2026"
  end

  def self.ms(value)
    value ? "#{value.round}ms" : "-"
  end

  def self.number(value, precision: 1)
    value ? value.round(precision).to_s : "-"
  end

  # Renders a box-drawn table.
  # columns: array of { label:, width:, align: :left|:right }
  # rows:    array of arrays (same length as columns)
  # Options:
  #   title:       string header above the table
  #   highlight:   lambda(row_array) → true to colour that row red
  def self.table(columns:, rows:, title: nil, highlight: nil)
    tw = terminal_width
    out = +""

    # Compute widths — if total exceeds terminal, shrink last column
    total = columns.sum { |c| c[:width] } + columns.size + 1 # +1 per border
    if total > tw && columns.size > 1
      overflow = total - tw
      columns.last[:width] = [ columns.last[:width] - overflow, 6 ].max
    end

    widths = columns.map { |c| c[:width] }

    top    = "\u250c" + widths.map { |w| "\u2500" * (w + 2) }.join("\u252c") + "\u2510"
    mid    = "\u251c" + widths.map { |w| "\u2500" * (w + 2) }.join("\u253c") + "\u2524"
    bottom = "\u2514" + widths.map { |w| "\u2500" * (w + 2) }.join("\u2534") + "\u2518"

    if title
      title_inner_width = widths.sum + (columns.size - 1) * 3 + 2
      title_top = "\u250c" + "\u2500" * (title_inner_width) + "\u2510"
      title_sep = "\u251c" + widths.map { |w| "\u2500" * (w + 2) }.join("\u252c") + "\u2524"
      out << "#{BOLD}#{CYAN}#{title_top}#{RESET}\n"
      out << "#{CYAN}\u2502#{RESET} #{BOLD}#{WHITE}#{truncate(title, title_inner_width - 1).ljust(title_inner_width - 1)}#{RESET}#{CYAN}\u2502#{RESET}\n"
      out << "#{CYAN}#{title_sep}#{RESET}\n"
    else
      out << "#{CYAN}#{top}#{RESET}\n"
    end

    # Header row
    header_cells = columns.each_with_index.map do |col, i|
      "#{BOLD}#{WHITE}#{truncate(col[:label], widths[i]).ljust(widths[i])}#{RESET}"
    end
    out << "#{CYAN}\u2502#{RESET} #{header_cells.join(" #{CYAN}\u2502#{RESET} ")} #{CYAN}\u2502#{RESET}\n"
    out << "#{CYAN}#{mid}#{RESET}\n"

    if rows.empty?
      empty_width = widths.sum + (columns.size - 1) * 3 + 2
      out << "#{CYAN}\u2502#{RESET} #{DIM}#{"(no data)".center(empty_width - 1)}#{RESET}#{CYAN}\u2502#{RESET}\n"
    else
      rows.each_with_index do |row, ri|
        bg = ri.odd? ? BG_ROW : ""
        is_red = highlight&.call(row)
        fg = is_red ? RED : ""

        cells = columns.each_with_index.map do |col, i|
          val = truncate(row[i].to_s, widths[i])
          col[:align] == :right ? val.rjust(widths[i]) : val.ljust(widths[i])
        end
        out << "#{bg}#{fg}#{CYAN}\u2502#{RESET}#{bg}#{fg} #{cells.join(" #{CYAN}\u2502#{RESET}#{bg}#{fg} ")} #{CYAN}\u2502#{RESET}\n"
      end
    end

    out << "#{CYAN}#{bottom}#{RESET}\n"
    out
  end
end

namespace :logs do
  desc "Per-hour request overview across the log files (highlights anomalies); optional DAYS=7 for a recent window"
  task :overview do
    puts "#{LogDisplay::BOLD}Scanning log files...#{LogDisplay::RESET}"

    days = ENV["DAYS"].to_i
    # A row per hour of every retained log is thousands of rows, and an anomaly
    # from weeks ago re-flags every run. The window keeps both current.
    files = days > 0 ? LogParser.recent_dated_files(days) : LogParser.discover_log_files
    if files.empty?
      puts "#{LogDisplay::RED}No production log files found in log/#{LogDisplay::RESET}"
      exit 0
    end
    puts "#{LogDisplay::DIM}Found #{files.size} file(s): #{files.map { |f| File.basename(f) }.join(", ")}#{LogDisplay::RESET}"

    hourly = Hash.new(0)

    LogParser.each_hour_bucket(files) do |bucket|
      hourly[bucket] += 1
    end

    if hourly.empty?
      puts "#{LogDisplay::YELLOW}No request lines found.#{LogDisplay::RESET}"
      exit 0
    end

    sorted = hourly.sort_by { |k, _| k }
    counts = sorted.map(&:last)
    median = counts.sort[counts.size / 2]
    threshold = median * 3

    rows = sorted.map { |hour, count| [ hour, count.to_s ] }

    puts LogDisplay.table(
      title: "Requests per hour (median: #{median}, anomaly threshold: #{threshold})",
      columns: [
        { label: "Hour", width: 18, align: :left },
        { label: "Requests", width: 10, align: :right }
      ],
      rows: rows,
      highlight: ->(row) { row[1].to_i > threshold }
    )

    anomalies = sorted.select { |_, c| c > threshold }
    if anomalies.any?
      puts "#{LogDisplay::RED}#{LogDisplay::BOLD}#{anomalies.size} anomalous hour(s) detected (>#{threshold} requests).#{LogDisplay::RESET}"
      puts "#{LogDisplay::DIM}Run: rake \"logs:report[DATE,HOUR]\" to investigate.#{LogDisplay::RESET}"
    end
  end

  desc "Report for a date or specific hour: rake \"logs:report[2026-02-23]\" or rake \"logs:report[2026-02-23,21]\""
  task :report, [ :date, :hour ] do |_t, args|
    date = args[:date]
    hour = args[:hour]

    unless date
      puts "#{LogDisplay::RED}Usage: rake \"logs:report[2026-02-23]\" or rake \"logs:report[2026-02-23,21]\"#{LogDisplay::RESET}"
      exit 1
    end

    whole_day = hour.nil?

    if whole_day
      puts "#{LogDisplay::BOLD}Analysing #{date} (full day) ...#{LogDisplay::RESET}"
    else
      puts "#{LogDisplay::BOLD}Analysing #{date} #{hour.rjust(2, "0")}:00\u2013#{hour.rjust(2, "0")}:59 ...#{LogDisplay::RESET}"
    end

    time_counts = Hash.new(0)
    endpoints   = Hash.new(0)
    ips         = Hash.new(0)
    agents      = Hash.new(0)
    hosts       = Hash.new(0)

    entries = whole_day ? LogParser.each_entry_for_date(date) : LogParser.each_entry_for_hour(date, hour.to_i)

    entries.each do |e|
      case e.line_type
      when :started
        bucket = whole_day ? e.timestamp.strftime("%H:00") : e.timestamp.strftime("%H:%M")
        time_counts[bucket] += 1
        ips[e.ip] += 1
        agents[e.user_agent] += 1
        hosts[e.host] += 1
      when :processing
        endpoints[e.detail] += 1
      end
    end

    if time_counts.empty?
      period = whole_day ? "that day" : "that hour"
      puts "#{LogDisplay::YELLOW}No requests found for #{period}.#{LogDisplay::RESET}"
      exit 0
    end

    # 1. Requests per time bucket
    if whole_day
      all_buckets = (0..23).map { |h| format("%02d:00", h) }
      bucket_label = "Hour"
      table_title = "1. Requests per hour"
    else
      hour_i = hour.to_i
      all_buckets = (0..59).map { |m| format("%02d:%02d", hour_i, m) }
      bucket_label = "Minute"
      table_title = "1. Requests per minute"
    end

    time_rows = all_buckets.map { |b| [ b, time_counts[b].to_s ] }
    peak_count = time_counts.values.max || 0
    time_median = time_counts.values.sort[time_counts.values.size / 2] || 0
    time_threshold = [ time_median * 3, 1 ].max

    puts LogDisplay.table(
      title: "#{table_title} (peak: #{peak_count})",
      columns: [
        { label: bucket_label, width: 8, align: :left },
        { label: "Requests", width: 10, align: :right }
      ],
      rows: time_rows,
      highlight: ->(row) { row[1].to_i > time_threshold }
    )

    # 2. Top 20 endpoints
    top_endpoints = endpoints.sort_by { |_, c| -c }.first(20)
    puts LogDisplay.table(
      title: "2. Top endpoints (controller#action)",
      columns: [
        { label: "Endpoint", width: 60, align: :left },
        { label: "Requests", width: 10, align: :right }
      ],
      rows: top_endpoints.map { |ep, c| [ ep, c.to_s ] }
    )

    # 3. Top 20 IPs
    top_ips = ips.sort_by { |_, c| -c }.first(20)
    puts LogDisplay.table(
      title: "3. Top IPs",
      columns: [
        { label: "IP", width: 40, align: :left },
        { label: "Requests", width: 10, align: :right }
      ],
      rows: top_ips.map { |ip, c| [ ip, c.to_s ] }
    )

    # 4. Top 20 user agents
    top_agents = agents.sort_by { |_, c| -c }.first(20)
    puts LogDisplay.table(
      title: "4. Top user agents",
      columns: [
        { label: "User Agent", width: 80, align: :left },
        { label: "Requests", width: 10, align: :right }
      ],
      rows: top_agents.map { |ua, c| [ ua, c.to_s ] }
    )

    # 5. Top 20 hosts
    top_hosts = hosts.sort_by { |_, c| -c }.first(20)
    puts LogDisplay.table(
      title: "5. Top hosts",
      columns: [
        { label: "Host", width: 50, align: :left },
        { label: "Requests", width: 10, align: :right }
      ],
      rows: top_hosts.map { |h, c| [ h, c.to_s ] }
    )

    total = time_counts.values.sum
    period = whole_day ? "day" : "hour"
    puts "#{LogDisplay::BOLD}Total requests in #{period}: #{total}#{LogDisplay::RESET}"
  end

  desc "Traffic report for a specific blog: rake \"logs:blog[joel]\" or rake \"logs:blog[joel,2026-02-23]\" or rake \"logs:blog[joel,2026-02-23,21]\""
  task :blog, [ :identifier, :date, :hour ] do |_t, args|
    identifier = args[:identifier]
    date = args[:date]
    hour = args[:hour]

    unless identifier
      puts "#{LogDisplay::RED}Usage: rake \"logs:blog[identifier]\" or rake \"logs:blog[identifier,2026-02-23]\" or rake \"logs:blog[identifier,2026-02-23,21]\"#{LogDisplay::RESET}"
      exit 1
    end

    hostname = identifier.include?(".") ? identifier : "#{identifier}.pagecord.com"

    if date && hour
      puts "#{LogDisplay::BOLD}Analysing #{hostname} — #{date} #{hour.rjust(2, "0")}:00\u2013#{hour.rjust(2, "0")}:59 ...#{LogDisplay::RESET}"
      entries = LogParser.each_entry_for_hour(date, hour.to_i)
    elsif date
      puts "#{LogDisplay::BOLD}Analysing #{hostname} — #{date} (full day) ...#{LogDisplay::RESET}"
      entries = LogParser.each_entry_for_date(date)
    else
      puts "#{LogDisplay::BOLD}Analysing #{hostname} — all available logs ...#{LogDisplay::RESET}"
      entries = LogParser.each_entry
    end

    time_counts = Hash.new(0)
    endpoints   = Hash.new(0)
    ips         = Hash.new(0)
    agents      = Hash.new(0)
    hosts       = Hash.new(0)

    entries.each do |e|
      next unless e.host == hostname

      case e.line_type
      when :started
        bucket = if hour
          e.timestamp.strftime("%H:%M")
        elsif date
          e.timestamp.strftime("%H:00")
        else
          e.timestamp.strftime("%Y-%m-%d")
        end
        time_counts[bucket] += 1
        ips[e.ip] += 1
        agents[e.user_agent] += 1
        hosts[e.host] += 1
      when :processing
        endpoints[e.detail] += 1
      end
    end

    if time_counts.empty?
      puts "#{LogDisplay::YELLOW}No requests found for #{hostname}.#{LogDisplay::RESET}"
      exit 0
    end

    # 1. Requests per time bucket
    if hour
      hour_i = hour.to_i
      all_buckets = (0..59).map { |m| format("%02d:%02d", hour_i, m) }
      bucket_label = "Minute"
      table_title = "1. Requests per minute"
    elsif date
      all_buckets = (0..23).map { |h| format("%02d:00", h) }
      bucket_label = "Hour"
      table_title = "1. Requests per hour"
    else
      all_buckets = time_counts.keys.sort
      bucket_label = "Date"
      table_title = "1. Requests per day"
    end

    time_rows = all_buckets.map { |b| [ b, time_counts[b].to_s ] }
    peak_count = time_counts.values.max || 0
    time_median = time_counts.values.sort[time_counts.values.size / 2] || 0
    time_threshold = [ time_median * 3, 1 ].max

    puts LogDisplay.table(
      title: "#{table_title} (peak: #{peak_count})",
      columns: [
        { label: bucket_label, width: 12, align: :left },
        { label: "Requests", width: 10, align: :right }
      ],
      rows: time_rows,
      highlight: ->(row) { row[1].to_i > time_threshold }
    )

    # 2. Top 20 endpoints
    top_endpoints = endpoints.sort_by { |_, c| -c }.first(20)
    puts LogDisplay.table(
      title: "2. Top endpoints (controller#action)",
      columns: [
        { label: "Endpoint", width: 60, align: :left },
        { label: "Requests", width: 10, align: :right }
      ],
      rows: top_endpoints.map { |ep, c| [ ep, c.to_s ] }
    )

    # 3. Top 20 IPs
    top_ips = ips.sort_by { |_, c| -c }.first(20)
    puts LogDisplay.table(
      title: "3. Top IPs",
      columns: [
        { label: "IP", width: 40, align: :left },
        { label: "Requests", width: 10, align: :right }
      ],
      rows: top_ips.map { |ip, c| [ ip, c.to_s ] }
    )

    # 4. Top 20 user agents
    top_agents = agents.sort_by { |_, c| -c }.first(20)
    puts LogDisplay.table(
      title: "4. Top user agents",
      columns: [
        { label: "User Agent", width: 80, align: :left },
        { label: "Requests", width: 10, align: :right }
      ],
      rows: top_agents.map { |ua, c| [ ua, c.to_s ] }
    )

    # 5. Top 20 hosts
    top_hosts = hosts.sort_by { |_, c| -c }.first(20)
    puts LogDisplay.table(
      title: "5. Top hosts",
      columns: [
        { label: "Host", width: 50, align: :left },
        { label: "Requests", width: 10, align: :right }
      ],
      rows: top_hosts.map { |h, c| [ h, c.to_s ] }
    )

    total = time_counts.values.sum
    puts "#{LogDisplay::BOLD}Total requests for #{hostname}: #{total}#{LogDisplay::RESET}"
  end

  desc "Performance report: rake \"logs:performance[2026-02-23]\" or rake \"logs:performance[2026-02-23,21]\"; optional HOST=joel"
  task :performance, [ :date, :hour ] do |_t, args|
    date = args[:date]
    hour = args[:hour]

    unless date
      puts "#{LogDisplay::RED}Usage: rake \"logs:performance[2026-02-23]\" or rake \"logs:performance[2026-02-23,21]\"#{LogDisplay::RESET}"
      exit 1
    end

    host_filter = ENV["HOST"].to_s.strip
    hostname = unless host_filter.empty?
      host_filter.include?(".") ? host_filter : "#{host_filter}.pagecord.com"
    end

    if hour
      puts "#{LogDisplay::BOLD}Analysing performance for #{date} #{hour.rjust(2, "0")}:00\u2013#{hour.rjust(2, "0")}:59 ...#{LogDisplay::RESET}"
      entries = LogParser.each_entry_for_hour(date, hour.to_i)
    else
      puts "#{LogDisplay::BOLD}Analysing performance for #{date} (full day) ...#{LogDisplay::RESET}"
      entries = LogParser.each_entry_for_date(date)
    end
    puts "#{LogDisplay::DIM}Host filter: #{hostname}#{LogDisplay::RESET}" if hostname

    records = LogPerformance.records_for(entries, host: hostname)

    if records.empty?
      puts "#{LogDisplay::YELLOW}No completed requests found for that period.#{LogDisplay::RESET}"
      exit 0
    end

    total = records.size
    durations = records.map { |record| record[:duration_ms] }.compact
    active_record_times = records.map { |record| record[:active_record_ms] }.compact
    query_counts = records.map { |record| record[:query_count] }.compact

    puts LogDisplay.table(
      title: "Summary (#{total} completed requests)",
      columns: [
        { label: "Metric", width: 20, align: :left },
        { label: "Average", width: 10, align: :right },
        { label: "P95", width: 10, align: :right },
        { label: "Max", width: 10, align: :right }
      ],
      rows: [
        [
          "Response time",
          LogDisplay.ms(LogPerformance.average(durations)),
          LogDisplay.ms(LogPerformance.percentile(durations, 95)),
          LogDisplay.ms(durations.max)
        ],
        [
          "ActiveRecord time",
          LogDisplay.ms(LogPerformance.average(active_record_times)),
          LogDisplay.ms(LogPerformance.percentile(active_record_times, 95)),
          LogDisplay.ms(active_record_times.max)
        ],
        [
          "Query count",
          LogDisplay.number(LogPerformance.average(query_counts)),
          LogDisplay.number(LogPerformance.percentile(query_counts, 95), precision: 0),
          query_counts.max || "-"
        ]
      ]
    )

    slowest_requests = records.sort_by { |record| -(record[:duration_ms] || 0) }.first(20)
    puts LogDisplay.table(
      title: "1. Slowest requests",
      columns: [
        { label: "Time", width: 8, align: :left },
        { label: "Status", width: 6, align: :right },
        { label: "Total", width: 8, align: :right },
        { label: "AR", width: 8, align: :right },
        { label: "Queries", width: 7, align: :right },
        { label: "Host", width: 28, align: :left },
        { label: "Endpoint", width: 42, align: :left },
        { label: "Request", width: 60, align: :left }
      ],
      rows: slowest_requests.map do |record|
        [
          record[:timestamp]&.strftime("%H:%M:%S") || "-",
          record[:status] || "-",
          LogDisplay.ms(record[:duration_ms]),
          LogDisplay.ms(record[:active_record_ms]),
          record[:query_count] || "-",
          record[:host] || "-",
          record[:endpoint] || "-",
          record[:path] || "-"
        ]
      end
    )

    endpoint_stats = LogPerformance.endpoint_stats(records)

    slow_endpoints = endpoint_stats.sort_by { |stat| -(stat[:p95_ms] || 0) }.first(20)
    puts LogDisplay.table(
      title: "2. Slowest endpoints by P95 response time",
      columns: [
        { label: "Endpoint", width: 60, align: :left },
        { label: "Requests", width: 10, align: :right },
        { label: "Avg", width: 8, align: :right },
        { label: "P95", width: 8, align: :right },
        { label: "Max", width: 8, align: :right },
        { label: "AR avg", width: 8, align: :right },
        { label: "Q avg", width: 7, align: :right },
        { label: "Q max", width: 7, align: :right }
      ],
      rows: slow_endpoints.map do |stat|
        [
          stat[:endpoint],
          stat[:count],
          LogDisplay.ms(stat[:average_ms]),
          LogDisplay.ms(stat[:p95_ms]),
          LogDisplay.ms(stat[:max_ms]),
          LogDisplay.ms(stat[:active_record_average_ms]),
          LogDisplay.number(stat[:query_average]),
          stat[:query_max] || "-"
        ]
      end
    )

    query_heavy_endpoints = endpoint_stats.sort_by { |stat| -(stat[:query_average] || 0) }.first(20)
    puts LogDisplay.table(
      title: "3. Query-heavy endpoints",
      columns: [
        { label: "Endpoint", width: 60, align: :left },
        { label: "Requests", width: 10, align: :right },
        { label: "Q avg", width: 7, align: :right },
        { label: "Q max", width: 7, align: :right },
        { label: "AR avg", width: 8, align: :right },
        { label: "P95", width: 8, align: :right }
      ],
      rows: query_heavy_endpoints.map do |stat|
        [
          stat[:endpoint],
          stat[:count],
          LogDisplay.number(stat[:query_average]),
          stat[:query_max] || "-",
          LogDisplay.ms(stat[:active_record_average_ms]),
          LogDisplay.ms(stat[:p95_ms])
        ]
      end
    )
  end

  desc "Signup funnel for a date: rake \"logs:signups[2026-09-01]\""
  task :signups, [ :date ] do |_t, args|
    date = args[:date]

    unless date
      puts "#{LogDisplay::RED}Usage: rake \"logs:signups[2026-09-01]\"#{LogDisplay::RESET}"
      exit 1
    end

    puts "#{LogDisplay::BOLD}Analysing signups for #{date} ...#{LogDisplay::RESET}"

    attempts = {}
    new_views = 0

    record_for = ->(uuid) { attempts[uuid] ||= { blocks: [] } }

    LogParser.each_entry_for_date(date) do |e|
      case e.line_type
      when :started
        if e.detail.start_with?("POST /signups")
          r = record_for.(e.uuid)
          r[:time] ||= e.timestamp
          r[:ip] ||= e.ip
          r[:ua] ||= e.user_agent
          r[:started] = true
        elsif e.detail.start_with?("GET /signups/new") || e.detail == "GET /signups"
          new_views += 1
        end
      when :processing
        if e.detail.start_with?("SignupsController#create")
          record_for.(e.uuid)[:processing] = true
        end
      when :completed
        if attempts.key?(e.uuid)
          attempts[e.uuid][:status] = e.status
        end
      when :other
        r = attempts[e.uuid]
        next unless r

        body = e.detail.to_s
        if body.start_with?("Parameters:")
          r[:subdomain] ||= body[/"subdomain"\s*=>\s*"([^"]+)"/, 1]
          r[:timezone] ||= body[/"timezone"\s*=>\s*"([^"]+)"/, 1]
          r[:referrer] ||= body[/"signup_referrer"\s*=>\s*"([^"]*)"/, 1]
          r[:source_note] ||= body[/"signup_source_note"\s*=>\s*"([^"]*)"/, 1]
        elsif body.include?("Honeypot field completed")
          r[:blocks] << "honeypot"
        elsif body.include?("Form completed too quickly") || body.include?("Invalid or missing form token")
          r[:blocks] << "form-time"
        elsif (m = body.match(/Suspicious email blocked:\s*(\S+)/))
          r[:blocks] << "suspicious-email"
          r[:suspicious_email] = m[1]
        elsif body.include?("Turnstile check failed")
          r[:blocks] << "turnstile"
        elsif body.include?("Signup validation failed")
          r[:validation_failed] = body[/Signup validation failed:\s*(.*)/, 1]
        end
      end
    end

    signups = attempts.values.select { |r| r[:processing] || r[:started] }

    # Plain-English funnel labels; the report is read at breakfast.
    block_label = {
      "honeypot" => "Honeypot caught",
      "form-time" => "Form too fast",
      "suspicious-email" => "Suspicious email",
      "turnstile" => "Turnstile blocked"
    }

    # Where did they come from? The note after the form ("a search") wins;
    # otherwise the referrer's utm_source, otherwise just the site name.
    source_for = ->(r) do
      note = r[:source_note].to_s.strip
      return note[0, 30] unless note.empty?

      ref = r[:referrer].to_s
      return "direct" if ref.empty?
      return ref[/utm_source=([^&]+)/, 1].to_s[0, 30] if ref.include?("utm_source=")

      host = ref[%r{https?://([^/?#]+)}, 1].to_s.sub(/\Awww\./, "")
      host.empty? ? "link" : host[0, 30]
    end

    # Chrome, Safari, Firefox... rather than the full user-agent firehose.
    browser_for = ->(ua) do
      ua = ua.to_s
      return "Bot" if ua =~ /bot|crawl|spider|slurp|mediapartners/i
      return "Script" if ua =~ /curl|Go-http|python|wget|httpclient/i
      return "In-app" if ua =~ /Electron|chatlyio|;wv/
      return "Opera" if ua.include?("OPR/")
      return "Edge" if ua.include?("Edg/")
      return "Firefox" if ua.include?("Firefox/")
      return "Safari" if ua.include?("Safari/") && ua.include?("Version/")
      return "Chrome" if ua.include?("Chrome/")
      "Other"
    end

    funnel = Hash.new(0)
    successes = []
    browsers = Hash.new(0)

    signups.each do |r|
      browsers[browser_for.(r[:ua])] += 1

      case r[:status]
      when 302
        funnel["Signed up"] += 1
        successes << r
      when 429
        funnel["Rate-limited"] += 1
      else
        if r[:blocks].any?
          funnel[block_label.fetch(r[:blocks].first, "Blocked")] += 1
        elsif r[:validation_failed]
          funnel["Validation failure"] += 1
        elsif r[:status] == 422
          # The only silent 422 path in SignupsController#create is the
          # banned-timezone reject, which logs nothing. Every other 422
          # leaves a warn/info line classified above.
          funnel["Banned timezone"] += 1
        elsif r[:status].nil?
          funnel["Unfinished"] += 1
        else
          funnel["Other"] += 1
        end
      end
    end

    puts LogDisplay.table(
      title: "Signup funnel for #{date} (#{signups.size} attempts, #{new_views} form views)",
      columns: [
        { label: "Stage", width: 20, align: :left },
        { label: "Count", width: 8, align: :right }
      ],
      rows: funnel.sort_by { |_, c| -c }.map { |stage, c| [ stage, c.to_s ] }
    )

    puts LogDisplay.table(
      title: "Successful signups (#{successes.size})",
      columns: [
        { label: "Time", width: 8, align: :left },
        { label: "Subdomain", width: 22, align: :left },
        { label: "Timezone", width: 22, align: :left },
        { label: "Source", width: 30, align: :left }
      ],
      rows: successes.sort_by { |r| r[:time].to_s }.map do |r|
        [
          r[:time]&.strftime("%H:%M:%S") || "-",
          r[:subdomain] || "-",
          r[:timezone] || "-",
          source_for.(r)
        ]
      end
    )

    # The one IP signal worth surfacing: distinct new blogs from one address.
    # Same-address retries of a single signup are normal and stay silent.
    successes.group_by { |r| r[:ip] }.each do |ip, rs|
      names = rs.map { |r| r[:subdomain] }.compact.uniq
      next if ip.nil? || names.size < 2

      puts "#{LogDisplay::DIM}Note: #{names.join(" and ")} signed up from the same address — worth a spam check.#{LogDisplay::RESET}"
    end

    puts LogDisplay.table(
      title: "Signup browsers",
      columns: [
        { label: "Browser", width: 12, align: :left },
        { label: "Attempts", width: 9, align: :right }
      ],
      rows: browsers.sort_by { |_, c| -c }.map { |b, c| [ b, c.to_s ] }
    )

    puts "#{LogDisplay::DIM}\"Signup validation failed\" lines carry the email address in plain text — " \
      "never paste those lines anywhere.#{LogDisplay::RESET}"
  end

  desc "AI bot robots.txt compliance: which disallowed crawlers still hit the site. rake \"logs:bots\" or rake \"logs:bots[2026-07-21]\"; optional DAYS=7 for a recent window"
  task :bots, [ :date ] do |_t, args|
    date = args[:date]
    days = ENV["DAYS"].to_i

    blocklist_path = File.join(Dir.pwd, "app/views/blogs/robots/_ai_training_crawlers.text.erb")
    unless File.exist?(blocklist_path)
      puts "#{LogDisplay::RED}AI crawler blocklist not found at #{blocklist_path}#{LogDisplay::RESET}"
      exit 1
    end

    tokens = File.readlines(blocklist_path).filter_map { |line| line[/^\s*User-agent:\s*(.+?)\s*$/, 1] }
    if tokens.empty?
      puts "#{LogDisplay::YELLOW}No User-agent tokens found in blocklist.#{LogDisplay::RESET}"
      exit 0
    end

    # Ambiguous tokens that are common words or short substrings. A match is a
    # signal, not proof, so flag them for human review before adding a Caddy
    # block rather than treating them as confirmed offenders.
    review = %w[lcc yak]

    # A rolling window keeps the table responsive: a token blocked in Caddy weeks
    # ago carries a cumulative count that drowns out whether the block worked.
    window = LogParser.recent_dated_files(days) if days > 0

    scope = if date
      date
    elsif window&.any?
      "#{LogParser.date_of(window.first)} to #{LogParser.date_of(window.last)}"
    else
      "all retained logs"
    end
    puts "#{LogDisplay::BOLD}Scanning #{scope} for #{tokens.size} disallowed AI bots ...#{LogDisplay::RESET}"

    entries = if date
      LogParser.each_entry_for_date(date)
    elsif window&.any?
      LogParser.each_entry(*window)
    else
      LogParser.each_entry
    end
    # needle is a cheap prefilter; boundary confirms the token isn't buried
    # inside a longer word (e.g. ExaBot inside VirexaBot).
    matchers = tokens.map do |token|
      needle = token.downcase
      [ token, needle, /(?<![a-z0-9])#{Regexp.escape(needle)}(?![a-z0-9])/ ]
    end
    hits = {}
    ip_tokens = Hash.new { |h, k| h[k] = {} }

    entries.each do |e|
      next unless e.line_type == :started
      ua = e.user_agent.to_s
      next if ua.empty?
      ua_down = ua.downcase

      matchers.each do |token, needle, boundary|
        next unless ua_down.include?(needle) && boundary.match?(ua_down)
        hit = hits[token] ||= { count: 0, ips: Hash.new(0), sample: ua }
        hit[:count] += 1
        hit[:ips][e.ip] += 1
        ip_tokens[e.ip][token] = true
      end
    end

    if hits.empty?
      puts "#{LogDisplay::GREEN}No disallowed AI bots seen in #{scope}. All quiet.#{LogDisplay::RESET}"
      exit 0
    end

    # An IP wearing three or more different bot identities is not the crawler it
    # claims to be. Reporting that share stops a token's count reading as
    # activity by the company whose name is on it.
    multi_identity = ip_tokens.each_with_object({}) { |(ip, ts), h| h[ip] = true if ts.size >= 3 }

    rows = hits.sort_by { |_, hit| -hit[:count] }.map do |token, hit|
      verdict = review.include?(token.downcase) ? "review" : "block"
      forged = hit[:ips].sum { |ip, n| multi_identity[ip] ? n : 0 }
      [ token, hit[:count].to_s, hit[:ips].size.to_s, "#{(100.0 * forged / hit[:count]).round}%", verdict, hit[:sample] ]
    end

    puts LogDisplay.table(
      title: "Traffic claiming disallowed AI bot user agents (#{scope})",
      columns: [
        { label: "Claimed token", width: 28, align: :left },
        { label: "Requests", width: 9, align: :right },
        { label: "IPs", width: 5, align: :right },
        { label: "Forged", width: 7, align: :right },
        { label: "Verdict", width: 7, align: :left },
        { label: "Sample user agent", width: 60, align: :left }
      ],
      rows: rows,
      highlight: ->(row) { row[4] == "block" }
    )

    to_block = rows.count { |row| row[4] == "block" }
    to_review = rows.count { |row| row[4] == "review" }
    puts "#{LogDisplay::BOLD}#{to_block} token(s) worth blocking in Caddy; #{to_review} generic-token match(es) to review.#{LogDisplay::RESET}"
    puts "#{LogDisplay::DIM}User agents are self-declared and unverified: these counts are what traffic CLAIMED to be, not what it was.#{LogDisplay::RESET}"
    puts "#{LogDisplay::DIM}\"Forged\" = share of requests from IPs that claimed 3+ different tokens. A high share means the count says nothing about the named company.#{LogDisplay::RESET}"
    puts "#{LogDisplay::DIM}Counts include the bots' own robots.txt fetches, which are compliance rather than violations.#{LogDisplay::RESET}"
  end

  desc "Live tail of production.log with per-minute request counter"
  task :watch do
    log_path = File.join(Dir.pwd, "log", "production.log")
    unless File.exist?(log_path)
      puts "#{LogDisplay::RED}#{log_path} not found#{LogDisplay::RESET}"
      exit 1
    end

    puts "#{LogDisplay::BOLD}Watching #{log_path} (Ctrl-C to stop)#{LogDisplay::RESET}"
    puts "#{LogDisplay::DIM}Showing per-minute request counts. Red alert at >500 req/min.#{LogDisplay::RESET}\n\n"

    current_minute = nil
    count = 0

    File.open(log_path, "r") do |f|
      # Seek to end
      f.seek(0, IO::SEEK_END)

      loop do
        line = f.gets
        if line.nil?
          sleep 0.2
          next
        end

        entry = LogParser.parse_line(line)
        next unless entry&.line_type == :started && entry.timestamp

        min_key = entry.timestamp.strftime("%Y-%m-%d %H:%M")

        if min_key != current_minute
          # Print previous minute's total
          if current_minute
            colour = count > 500 ? LogDisplay::RED : LogDisplay::GREEN
            alert = count > 500 ? " #{LogDisplay::RED}#{LogDisplay::BOLD}!! HIGH TRAFFIC !!#{LogDisplay::RESET}" : ""
            puts "#{LogDisplay::DIM}#{current_minute}#{LogDisplay::RESET}  #{colour}#{LogDisplay::BOLD}#{count} requests#{LogDisplay::RESET}#{alert}"
          end
          current_minute = min_key
          count = 0
        end

        count += 1
      end
    end
  rescue Interrupt
    # Print final count
    if current_minute && count > 0
      colour = count > 500 ? LogDisplay::RED : LogDisplay::GREEN
      puts "\n#{LogDisplay::DIM}#{current_minute}#{LogDisplay::RESET}  #{colour}#{LogDisplay::BOLD}#{count} requests (partial)#{LogDisplay::RESET}"
    end
    puts "\n#{LogDisplay::DIM}Stopped.#{LogDisplay::RESET}"
  end
end
