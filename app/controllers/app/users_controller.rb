class App::UsersController < AppController

  def update
    if Current.user.update(user_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("bio-response", partial: "bio_response", locals: { message: "✅ Bio updated!" })
        end
        format.html { redirect_to @user }
      end
    end
  end


  private

    def user_params
      params.require(:user).permit(:bio)
    end
end
