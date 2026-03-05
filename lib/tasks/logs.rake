require_relative "../log_parser"

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
  desc "Per-hour request overview across all log files (highlights anomalies)"
  task :overview do
    puts "#{LogDisplay::BOLD}Scanning log files...#{LogDisplay::RESET}"

    files = LogParser.discover_log_files
    if files.empty?
      puts "#{LogDisplay::RED}No production log files found in log/#{LogDisplay::RESET}"
      exit 0
    end
    puts "#{LogDisplay::DIM}Found #{files.size} file(s): #{files.map { |f| File.basename(f) }.join(", ")}#{LogDisplay::RESET}"

    hourly = Hash.new(0)

    LogParser.each_hour_bucket do |bucket|
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
