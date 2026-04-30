class App::Pages::TrashController < AppController
  def show
    @trashed_pages = Current.user.blog.pages.discarded.order(discarded_at: :desc)
  end

  def create
    page = Current.user.blog.pages.kept.find_by!(token: params[:page_token])
    page.discard!
    Current.user.blog.update!(home_page_id: nil) if page.home_page?
    redirect_to app_pages_path, notice: "Page was successfully deleted."
  end

  def destroy
    Current.user.blog.pages.discarded.destroy_all
    redirect_to app_pages_trash_path, notice: "Trash was successfully emptied"
  end
end
