class AppController < ApplicationController
  layout "admin"

  include Authorization

  before_action :load_user

  private

    def load_user
      @user = Current.user
    end
end
