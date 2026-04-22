class GeoIp
  DB_PATH = Rails.root.join("db", "dbip-country-lite.mmdb")

  def self.lookup(ip)
    return nil unless File.exist?(DB_PATH)

    result = db.lookup(ip)
    result&.found? ? result.country.iso_code : nil
  rescue => e
    Rails.logger.warn("GeoIP lookup failed for #{ip}: #{e.message}")
    nil
  end

  def self.db
    @db ||= MaxMindDB.new(DB_PATH.to_s)
  end
end
