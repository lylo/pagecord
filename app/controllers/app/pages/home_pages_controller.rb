class App::Pages::HomePagesController < App::BaseController
  def create
    page = @blog.pages.kept.find_by!(token: params[:page_token])
    @blog.update!(home_page_id: page.id)

    redirect_to app_pages_path, notice: "Home page set!"
  end
end
