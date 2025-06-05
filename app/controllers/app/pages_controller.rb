class App::PagesController < AppController
  # GET /app/pages
  def index
    @pages = Current.user.blog.pages.published.order(:title)
    @drafts = Current.user.blog.pages.draft.order(:title)
  end

  # GET /app/pages/new
  def new
    @page = Current.user.blog.pages.build
  end

  # POST /app/pages
  def create
    @page = Current.user.blog.pages.build(page_params)

    if @page.save
      redirect_to app_pages_path, notice: "Page was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /app/pages/:token/edit
  def edit
    @page = Current.user.blog.pages.find_by!(token: params[:token])
  end

  # PATCH/PUT /app/pages/:token
  def update
    @page = Current.user.blog.pages.find_by!(token: params[:token])

    if @page.update(page_params)
      redirect_to app_pages_path, notice: "Page was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /app/pages/:token
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
