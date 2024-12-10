class PublicController < ApplicationController
  layout "public"

  caches_page :terms, :privacy, :faq, :pagecord_vs_hey_world

  def index
    redirect_to app_root_path if logged_in?
  end

  def terms
  end

  def privacy
  end

  def faq
  end
end
