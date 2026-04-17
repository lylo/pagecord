class Api::Micropub::MediaController < Api::AttachmentsController
  private

    def render_blob(blob)
      response.headers["Location"] = url_for(blob)
      head :created
    end
end
