class Blogs::StandardSitePublicationsController < Blogs::BaseController
  def show
    publication = @blog.standard_site_publication

    if publication&.synced? && publication.at_uri.present?
      render plain: publication.at_uri, content_type: "text/plain"
    else
      head :not_found
    end
  end
end
