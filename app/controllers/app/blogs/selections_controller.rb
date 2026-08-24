class App::Blogs::SelectionsController < App::BaseController
  def create
    session[:current_blog_id] = Current.user.blogs.find(params[:blog_id]).id

    redirect_to app_root_path
  end
end
