class App::Pages::RestorationsController < AppController
  def create
    page = Current.user.blog.pages.discarded.find_by!(token: params[:page_token])
    page.undiscard!
    redirect_to app_pages_trash_path, notice: "Page was successfully restored"
  end
end
