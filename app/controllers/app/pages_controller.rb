class App::PagesController < AppController
  include EditorPreparation

  def index
    persist_sort_preference if params[:sort].present?

    @sort = selected_sort
    @pages = @blog.pages.kept.published.order(pages_order)
    @drafts = @blog.pages.kept.draft.order(:title)
  end

  def new
    @page = @blog.pages.build
  end

  def create
    @page = @blog.pages.build(page_params)

    return render_stale_form_context unless context_blog_id_matches_current_blog?

    if @page.save
      redirect_to app_pages_path, notice: "Page was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @page = @blog.pages.kept.find_by!(token: params[:token])
    prepare_content_for_editor(@page)
  end

  def update
    @page = @blog.pages.kept.find_by!(token: params[:token])

    if @page.update(page_params)
      redirect_to app_pages_path, notice: "Page was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @page = @blog.pages.find_by!(token: params[:token])
    @blog.update!(home_page_id: nil) if @page.home_page?
    @page.destroy!
    redirect_to app_pages_trash_path, notice: "Page was permanently deleted."
  end

  def set_as_home_page
    @page = @blog.pages.kept.find_by!(token: params[:token])
    @blog.update!(home_page_id: @page.id)
    redirect_to app_pages_path, notice: "Home page set!"
  end

  private

    def selected_sort
      params[:sort] == "updated" || cookies.encrypted[:pages_sort] == "updated" ? "updated" : "alpha"
    end

    def pages_order
      @sort == "updated" ? Arel.sql("updated_at DESC, LOWER(title)") : Arel.sql("CASE WHEN id = #{@blog.home_page_id.to_i} THEN 0 ELSE 1 END, LOWER(title), updated_at DESC")
    end

    def persist_sort_preference
      if params[:sort] == "updated"
        cookies.encrypted[:pages_sort] = {
          value: "updated",
          expires: 1.year.from_now
        }
      else
        cookies.delete(:pages_sort)
      end
    end

    def page_params
      status = params[:button] == "save_draft" ? :draft : :published
      permitted = [ :title, :content, :slug, :hidden ]
      permitted += [ :open_graph_image, :open_graph_image_suppressed ] if Current.user.has_premium_access?
      params.require(:post).permit(*permitted).merge(is_page: true, status: status)
    end
end
