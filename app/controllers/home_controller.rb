class HomeController < ApplicationController
  include AttributionTrackable, PubliclyCached

  rate_limit to: 20, within: 1.minute, only: [ :index ]
  before_action :set_cache_headers, only: [ :index ]

  def index
  end

  private

    def set_cache_headers
      return if signup_attribution.present?

      cache_publicly(maxage: 1.hour)
    end
end
