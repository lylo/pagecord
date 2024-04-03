class HomeController < ApplicationController

  def index
    redirect_to app_root_path if logged_in?
  end
end
