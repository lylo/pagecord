module Public
  class RobotsController < ApplicationController
    layout false

    def show
      render formats: :text, content_type: "text/plain"
    end
  end
end
