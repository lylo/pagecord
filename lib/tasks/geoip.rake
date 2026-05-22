namespace :geoip do
  desc "Download latest DB-IP Lite country database"
  task update: :environment do
    require "zlib"

    date = Date.current.strftime("%Y-%m")
    url = "https://download.db-ip.com/free/dbip-country-lite-#{date}.mmdb.gz"
    dest = Rails.root.join("db", "dbip-country-lite.mmdb")

    puts "Downloading dbip-country-lite (#{date})..."

    response = HTTParty.get(url, follow_redirects: true)
    raise "Download failed: #{response.code} #{response.message}" unless response.success?

    mmdb = Zlib::GzipReader.new(StringIO.new(response.body)).read
    File.binwrite(dest, mmdb)

    # Clear cached db instance so it picks up the new file
    GeoIp.instance_variable_set(:@db, nil)

    puts "Updated #{dest} (#{File.size(dest)} bytes)"
  end
end
