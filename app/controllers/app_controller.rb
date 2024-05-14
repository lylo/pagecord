class AppController < ApplicationController
  layout "app"

  include Authorization

  before_action :load_user

  private

    def load_user
      puts "loading user: #{Current.user.username}"
      @user = Current.user
    end
end
