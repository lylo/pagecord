class AppController < ApplicationController
  layout "app"

  include Authorization, FreeTrial

  before_action :load_user

  private

    def load_user
      @user = Current.user
    end
end
