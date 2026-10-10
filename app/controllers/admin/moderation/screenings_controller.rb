class Admin::Moderation::ScreeningsController < Admin::BaseController
  def index
    @accuracy = User::Screening::Accuracy.new
  end
end
