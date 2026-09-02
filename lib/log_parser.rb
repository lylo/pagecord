require "zlib"
require "time"
require "date"

class LogParser
  Entry = Struct.new(
    :timestamp,
    :level,
    :uuid,
    :host,
    :ip,
    :user_agent,
    :line_type,
    :detail,
    :status,
    :duration_ms,
    :views_ms,
    :active_record_ms,
    :query_count,
    :cached_query_count,
    :gc_ms,
    keyword_init: true
  )

  # line_type is one of :started, :processing, :completed, :other
  # detail holds the type-specific info:
  #   :started    → "GET /some/path"
  #   :processing → "Blogs::PostsController#show as HTML"
  #   :completed  → "200 OK in 45ms (...)"
  #   :other      → the raw remainder

  # Timestamp format: 2026-02-23T21:38:00+00:00
  # Positions:        0         1         2
  #                   0123456789012345678901234
  TS_FORMAT = "%Y-%m-%dT%H:%M:%S%z"

  HEADER_RE = /\A
    (?<ts>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+\d{2}:\d{2})\s+
    (?<level>\w+)\s+
    \[(?<uuid>[^\]]*)\]\s+
    \[host=(?<host>[^\]]*)\]\s+
    \[ip=(?<ip>[^\]]*)\]\s+
    \[user_agent=(?<ua>[^\]]*)\]\s+
    (?<body>.*)
  \z/x

  DATED_LOG_RE  = /\Aproduction\.log\.\d{4}-\d{2}-\d{2}\.gz\z/

  STARTED_RE    = /Started\s+(\w+)\s+"([^"]+)"/
  PROCESSING_RE = /Processing\s+by\s+(\S+)/
  COMPLETED_RE  = /Completed\s+(?<status>\d{3})\s+(?<status_text>.*?)\s+in\s+(?<duration>[\d.]+)ms(?:\s+\((?<breakdown>.*)\))?/

  def self.each_entry(*paths, &block)
    return enum_for(:each_entry, *paths) unless block_given?

    paths = discover_log_files if paths.empty?

    paths.each do |path|
      open_file(path) do |io|
        io.each_line do |line|
          entry = parse_line(line)
          yield entry if entry
        end
      end
    end
  end

  # Fast path: only yields entries matching the given date and hour.
  # Skips lines via cheap string prefix check before any regex/parsing.
  def self.each_entry_for_hour(date_str, hour, &block)
    return enum_for(:each_entry_for_hour, date_str, hour) unless block_given?

    hour_prefix = format("%sT%02d", date_str, hour.to_i) # e.g. "2026-02-23T21"

    each_file(date_str) do |io|
      io.each_line do |line|
        next unless line.start_with?(hour_prefix)
        entry = parse_line(line)
        yield entry if entry
      end
    end
  end

  # Fast path: only yields entries matching the given date.
  def self.each_entry_for_date(date_str, &block)
    return enum_for(:each_entry_for_date, date_str) unless block_given?

    date_prefix = "#{date_str}T" # e.g. "2026-02-23T"

    each_file(date_str) do |io|
      io.each_line do |line|
        next unless line.start_with?(date_prefix)
        entry = parse_line(line)
        yield entry if entry
      end
    end
  end

  # Overview fast path: only needs hour bucket + "Started" check.
  # Skips full regex parsing entirely — just string-slices the timestamp.
  def self.each_hour_bucket(paths = nil, &block)
    return enum_for(:each_hour_bucket, paths) unless block_given?

    each_file_in(paths) do |io|
      io.each_line do |line|
        next unless line.include?("Started ")
        # Extract "YYYY-MM-DD HH:00" from timestamp at line start
        next unless line.length > 13 && line[4] == "-" && line[10] == "T"
        yield "#{line[0, 10]} #{line[11, 2]}:00"
      end
    end
  end

  def self.discover_log_files
    dir = File.join(Dir.pwd, "log")
    return [] unless Dir.exist?(dir)

    Dir.glob(File.join(dir, "production.log*")).sort_by do |f|
      # Sort: production.log first, then by rotation number
      base = File.basename(f)
      if base == "production.log"
        -1
      else
        num = base[/\.(\d+)/, 1].to_i
        num
      end
    end
  end

  def self.open_file(path, &block)
    if path.end_with?(".gz")
      Zlib::GzipReader.open(path) do |gz|
        yield gz
      end
    else
      File.open(path, "r") do |f|
        yield f
      end
    end
  rescue Zlib::GzipFile::Error
    # File has .gz extension but isn't gzipped — read as plain text
    File.open(path, "r") { |f| yield f }
  rescue Errno::ENOENT
    # File disappeared between discovery and open
  end

  def self.parse_line(line)
    line = line.chomp
    m = HEADER_RE.match(line)
    return nil unless m

    ts = Time.strptime(m[:ts], TS_FORMAT) rescue nil

    body = m[:body]
    line_type, detail, attributes = classify_body(body)

    Entry.new(
      timestamp: ts,
      level: m[:level],
      uuid: m[:uuid],
      host: m[:host],
      ip: m[:ip],
      user_agent: m[:ua],
      line_type: line_type,
      detail: detail,
      **attributes
    )
  end

  def self.classify_body(body)
    if (sm = STARTED_RE.match(body))
      [ :started, "#{sm[1]} #{sm[2]}", {} ]
    elsif (pm = PROCESSING_RE.match(body))
      [ :processing, pm[1], {} ]
    elsif (cm = COMPLETED_RE.match(body))
      detail = "#{cm[:status]} #{cm[:status_text]} in #{cm[:duration]}ms"
      [ :completed, detail, completed_attributes(cm) ]
    else
      [ :other, body, {} ]
    end
  end

  def self.completed_attributes(match)
    breakdown = match[:breakdown].to_s

    {
      status: match[:status].to_i,
      duration_ms: match[:duration].to_f,
      views_ms: duration_component(breakdown, "Views"),
      active_record_ms: duration_component(breakdown, "ActiveRecord"),
      query_count: query_count_component(breakdown, 1),
      cached_query_count: query_count_component(breakdown, 2),
      gc_ms: duration_component(breakdown, "GC")
    }
  end

  def self.duration_component(breakdown, name)
    match = breakdown.match(/#{Regexp.escape(name)}:\s+([\d.]+)ms/)
    match[1].to_f if match
  end

  def self.query_count_component(breakdown, index)
    match = breakdown.match(/ActiveRecord:\s+[\d.]+ms\s+\((\d+)\s+queries,\s+(\d+)\s+cached\)/)
    match[index].to_i if match
  end

  # Iterates over the discovered log files, yielding each IO. Given a date, only
  # opens the files that can hold it.
  def self.each_file(date_str = nil, &block)
    each_file_in(date_str ? files_for_date(date_str) : nil, &block)
  end

  def self.each_file_in(paths, &block)
    (paths || discover_log_files).each do |path|
      open_file(path) { |io| yield io }
    end
  end

  # The calendar day a dated archive is named for.
  def self.date_of(path)
    File.basename(path)[/\d{4}-\d{2}-\d{2}/]
  end

  # The newest dated archives, oldest first, for reports over a recent window.
  def self.recent_dated_files(days)
    discover_log_files.select { |f| DATED_LOG_RE.match?(File.basename(f)) }.sort.last(days)
  end

  # Rotation happens shortly after midnight UTC, so a day's entries land in the
  # archive named for it and the tail of the previous day's. Anything not named
  # for a date (the live log, a numbered rotation) is always a candidate.
  def self.files_for_date(date_str)
    files = discover_log_files
    return files unless files.any? { |f| DATED_LOG_RE.match?(File.basename(f)) }

    previous = (Date.iso8601(date_str).prev_day.iso8601 rescue nil)
    files.select do |f|
      base = File.basename(f)
      !DATED_LOG_RE.match?(base) || base.include?(date_str) || (previous && base.include?(previous))
    end
  end

  private_class_method :each_file, :each_file_in
end
