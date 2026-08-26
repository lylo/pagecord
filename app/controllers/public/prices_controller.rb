module Public
  class PricesController < ApplicationController
    PLANS = %i[annual monthly supporter].freeze

    # Private, so the visitor's own browser holds it and a shared cache never
    # can: one country's prices in a shared cache would reach every country.
    def show
      expires_in 1.hour, public: false

      render json: PLANS.index_with { |plan| localised_price(plan) }
    end
  end
end
