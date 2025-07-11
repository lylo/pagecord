class App::PagesController < AppController
  def index
    @pages = Current.user.blog.pages.published.order(:title)
    @drafts = Current.user.blog.pages.draft.order(:title)
  end

  def new
    @page = Current.user.blog.pages.build
  end

  def create
    @page = Current.user.blog.pages.build(page_params)

    if @page.save
      redirect_to app_pages_path, notice: "Page was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @page = Current.user.blog.pages.find_by!(token: params[:token])
  end

  def update
    @page = Current.user.blog.pages.find_by!(token: params[:token])

    if @page.update(page_params)
      redirect_to app_pages_path, notice: "Page was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @page = Current.user.blog.pages.find_by!(token: params[:token])
    @page.destroy!
    redirect_to app_pages_path, notice: "Page was successfully deleted."
  end

  private

    def page_params
      status = params[:button] == "save_draft" ? :draft : :published

      params.require(:post).permit(:title, :content, :slug, :show_in_navigation).merge(is_page: true, status: status)
    end
end
