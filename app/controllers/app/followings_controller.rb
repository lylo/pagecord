class App::FollowingsController < AppController
  include Pagy::Backend
  include ActionView::RecordIdentifier

  def index
    @pagy, @followees = pagy(Current.user.followees, limit: 15)
  end

  def create
    @user = User.find(params[:user_id])

    begin
      Current.user.follow(@user)
    rescue => e
      head :bad_request and return
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("#{dom_id(@user)}-follow-button", partial: "users/follow_button", locals: { user: @user })
      end
    end
  end

  def destroy
    @user = User.find(params[:user_id])

    begin
      Current.user.unfollow(@user)
    rescue => e
      head :bad_request and return
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("#{dom_id(@user)}-follow-button", partial: "users/follow_button", locals: { user: @user })
      end
    end
  end
end
