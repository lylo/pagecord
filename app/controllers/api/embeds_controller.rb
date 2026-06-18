require "open-uri"
require "nokogiri"

class Api::EmbedsController < ApplicationController
  skip_before_action :domain_check
  skip_forgery_protection only: :bandcamp

  rate_limit to: 30, within: 1.minute, only: :bandcamp, with: :rate_limit_reached

  def bandcamp
    url = params[:url]
    return render json: { error: "Invalid Bandcamp URL" }, status: :unprocessable_entity unless bandcamp_url?(url)

    embed_url = og_video_attribute(url)

    if embed_url
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
      Rails.cache.fetch([ "bandcamp_embed", url ], expires_in: 7.days, race_condition_ttl: 10.seconds) do
        doc = Nokogiri::HTML(URI.open(url, open_timeout: 2, read_timeout: 3))
        meta_tag = doc.at("meta[property=\"og:video\"]")
        meta_tag&.attr("content")
      end
    end

    def rate_limit_reached
      render json: { error: "Rate limit exceeded" }, status: :too_many_requests
    end
end
