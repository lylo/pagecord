module Public
  class LlmsController < ApplicationController
    layout false

    caches_page :show

    def show
      render formats: :text, content_type: "text/plain"
    end
  end
end
