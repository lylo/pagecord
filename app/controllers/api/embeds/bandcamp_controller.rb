require "open-uri"
require "nokogiri"

class Api::Embeds::BandcampController < ApplicationController
  rate_limit to: 60, within: 1.minute

  skip_before_action :domain_check

  def show
    url = params[:url]
    return render json: { error: "Invalid Bandcamp URL" }, status: :unprocessable_entity unless bandcamp_url?(url)

    if embed_url = og_video_attribute(url)
      set_cache_headers
      render json: { embed_url: embed_url }
    else
      render json: { error: "No og:video found" }, status: :unprocessable_entity
    end
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

    def bandcamp_url?(url)
      uri = URI.parse(url)
      uri.is_a?(URI::HTTPS) && (uri.host == "bandcamp.com" || uri.host&.end_with?(".bandcamp.com"))
    rescue URI::InvalidURIError
      false
    end

    def og_video_attribute(url)
      Rails.cache.fetch([ "bandcamp_embed", url ], expires_in: 7.days, race_condition_ttl: 10.seconds, skip_nil: true) do
        doc = Nokogiri::HTML(URI.open(url, open_timeout: 2, read_timeout: 3))
        doc.at("meta[property=\"og:video\"]")&.attr("content")
      end
    end

    # A session cookie makes Cloudflare bypass the cache.
    def set_cache_headers
      request.session_options[:skip] = true
      expires_in 1.day, public: true
    end
end
