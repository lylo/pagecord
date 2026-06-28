class Api::Micropub::MediaController < Api::AttachmentsController
  private

    def allow_access_token_parameter?
      true
    end

    def render_blob(blob)
      response.headers["Location"] = url_for(blob)
      head :created
    end
end
