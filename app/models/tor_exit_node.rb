class TorExitNode
  LIST_URL = URI("https://check.torproject.org/torbulkexitlist")
  CACHE_KEY = "tor_exit_nodes"

  def self.include?(ip)
    addresses.include?(ip)
  end

  def self.addresses
    Rails.cache.read(CACHE_KEY) || Set.new
  end

  def self.refresh
    response = Net::HTTP.get_response(LIST_URL)
    Rails.cache.write(CACHE_KEY, response.body.split.to_set, expires_in: 2.days) if response.is_a?(Net::HTTPSuccess)
  end
end
