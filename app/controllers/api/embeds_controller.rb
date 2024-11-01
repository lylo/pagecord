require "open-uri"
require "nokogiri"

class Api::EmbedsController < ApplicationController
  skip_before_action :domain_check

  def bandcamp
    url = params[:url]
    embed_url = og_video_attribute(url)

    if embed_url
      render json: { embed_url: embed_url }
    else
      render json: { error: 'No og:video found' }, status: :unprocessable_entity
    end
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

    def og_video_attribute(url)
      doc = Nokogiri::HTML(URI.open(url))
      meta_tag = doc.at("meta[property=\"og:video\"]")
      meta_tag&.attr("content")
    end
end
