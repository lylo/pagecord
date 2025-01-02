class App::Blogs::SocialLinksController < AppController
  def new
    @social_link = @blog.social_links.build

    respond_to do |format|
      format.turbo_stream
    end
  end
end
