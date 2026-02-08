class App::Pages::TrashController < AppController
  def index
    @trashed_pages = Current.user.blog.pages.discarded.order(discarded_at: :desc)
  end

  def destroy
    page = Current.user.blog.pages.discarded.find_by!(token: params[:token])
    page.undiscard!
    redirect_to app_pages_trash_index_path, notice: "Page was successfully restored"
  end
end
