class HomeController < ApplicationController
  rate_limit to: 20, within: 1.minute, only: [ :index ]
  before_action :set_cache_headers, only: [ :index ]

  def index
  end

  private

    def set_cache_headers
      return if logged_in?
      return if signup_attribution.present?

      expires_in 0, public: true, "s-maxage": 1.hour.to_i, "stale-while-revalidate": 10.minutes.to_i
    end
end
