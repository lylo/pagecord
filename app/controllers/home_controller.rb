class HomeController < ApplicationController
  rate_limit to: 20, within: 1.minute, only: [ :index ]

  def index
  end
end
