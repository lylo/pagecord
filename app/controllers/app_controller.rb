class AppController < ApplicationController
  layout "app"

  include Authorization

  before_action :load_user

  private

    def load_user
      @user = Current.user
      @blog = @user.blog
    end
end
