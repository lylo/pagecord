class App::Settings::UsersController < AppController
  def destroy
    DestroyUserJob.perform_later(@user.id)

    redirect_to root_path
  end
end
