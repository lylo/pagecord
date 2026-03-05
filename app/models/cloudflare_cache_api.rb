class CloudflareCacheApi
  def purge_blog(blog)
    zone_id = ENV["CLOUDFLARE_ZONE_ID"]
    api_token = ENV["CLOUDFLARE_API_TOKEN"]
    return unless zone_id.present? && api_token.present?

    response = HTTParty.post(
      "https://api.cloudflare.com/client/v4/zones/#{zone_id}/purge_cache",
      headers: {
        "Authorization" => "Bearer #{api_token}",
        "Content-Type" => "application/json"
      },
      body: { tags: [ blog.subdomain ] }.to_json
    )

    unless response.success?
      raise "Cloudflare cache purge failed for #{blog.subdomain}: #{response.code} #{response.body}"
    end
  end
end
