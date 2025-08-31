namespace :cache do
  desc "Expire the cache for the home page"
  task expire_static_pages: :environment do
    ActionController::Base.new.expire_page("/")
    ActionController::Base.new.expire_page("/faq")
    ActionController::Base.new.expire_page("/terms")
    ActionController::Base.new.expire_page("/privacy")
    ActionController::Base.new.expire_page("/pagecord-vs-hey-world")
    ActionController::Base.new.expire_page("/pagecord-vs-wordpress")
    ActionController::Base.new.expire_page("/pagecord-vs-substack")
  end

  desc "Show readable cache statistics"
  task stats: :environment do
    case Rails.cache
    when ActiveSupport::Cache::MemCacheStore
      show_memcache_stats
    when ActiveSupport::Cache::MemoryStore
      show_memory_store_stats
    else
      puts "Cache store type: #{Rails.cache.class}"
      puts "Stats not available for this cache store type"
    end
  end

  private

    def show_memcache_stats
      stats = Rails.cache.stats.values.first # Get first (and likely only) server

      puts "=== Memcached Statistics ==="
      puts

      # Memory usage
      memory_used = stats["bytes"].to_f
      memory_limit = stats["limit_maxbytes"].to_f
      memory_percent = (memory_used / memory_limit * 100).round(2)

      puts "Memory Usage:"
      puts "  Used: #{format_bytes(memory_used)} (#{memory_percent}%)"
      puts "  Limit: #{format_bytes(memory_limit)}"
      puts "  Available: #{format_bytes(memory_limit - memory_used)}"
      puts

      # Hit rate
      hits = stats["get_hits"].to_i
      misses = stats["get_misses"].to_i
      total = hits + misses
      hit_rate = total > 0 ? (hits.to_f / total * 100).round(2) : 0

      puts "Performance:"
      puts "  Hit Rate: #{hit_rate}% (#{hits} hits, #{misses} misses)"
      puts "  Total Items: #{stats["curr_items"]}"
      puts "  Total Reads: #{stats["cmd_get"]}"
      puts "  Total Writes: #{stats["cmd_set"]}"
    end

    def show_memory_store_stats
      puts "=== Memory Store Statistics ==="
      puts
      puts "Cache store: #{Rails.cache.class}"
      puts "Environment: #{Rails.env}"
      puts
      puts "Note: MemoryStore doesn't provide detailed statistics."
      puts "Switch to production environment to see Memcached stats:"
      puts "  RAILS_ENV=production rails cache:stats"
    end

    def format_bytes(bytes)
      units = [ "B", "KB", "MB", "GB" ]
      size = bytes.to_f
      unit_index = 0

      while size >= 1024 && unit_index < units.length - 1
        size /= 1024.0
        unit_index += 1
      end

      "#{size.round(2)} #{units[unit_index]}"
    end
end
