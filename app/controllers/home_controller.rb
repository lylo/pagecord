class HomeController < ApplicationController
  rate_limit to: 5, within: 1.minute, only: [ :index ]

  def index
    redirect_to app_root_path if logged_in?
  end
end
