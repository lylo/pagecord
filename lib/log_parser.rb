require "zlib"
require "time"

class LogParser
  Entry = Struct.new(:timestamp, :level, :uuid, :host, :ip, :user_agent, :line_type, :detail, keyword_init: true)

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

  STARTED_RE    = /Started\s+(\w+)\s+"([^"]+)"/
  PROCESSING_RE = /Processing\s+by\s+(\S+)/
  COMPLETED_RE  = /Completed\s+(.*)/

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

    each_file do |io|
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

    each_file do |io|
      io.each_line do |line|
        next unless line.start_with?(date_prefix)
        entry = parse_line(line)
        yield entry if entry
      end
    end
  end

  # Overview fast path: only needs hour bucket + "Started" check.
  # Skips full regex parsing entirely — just string-slices the timestamp.
  def self.each_hour_bucket(&block)
    return enum_for(:each_hour_bucket) unless block_given?

    each_file do |io|
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
    line_type, detail = classify_body(body)

    Entry.new(
      timestamp: ts,
      level: m[:level],
      uuid: m[:uuid],
      host: m[:host],
      ip: m[:ip],
      user_agent: m[:ua],
      line_type: line_type,
      detail: detail
    )
  end

  def self.classify_body(body)
    if (sm = STARTED_RE.match(body))
      [ :started, "#{sm[1]} #{sm[2]}" ]
    elsif (pm = PROCESSING_RE.match(body))
      [ :processing, pm[1] ]
    elsif (cm = COMPLETED_RE.match(body))
      [ :completed, cm[1] ]
    else
      [ :other, body ]
    end
  end

  # Iterates over all discovered log files, yielding each IO.
  def self.each_file(&block)
    discover_log_files.each do |path|
      open_file(path) { |io| yield io }
    end
  end

  private_class_method :each_file
end
