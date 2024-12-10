class PublicController < ApplicationController
  layout "home"

  caches_page :terms, :privacy, :faq, :pagecord_vs_hey_world

  def terms
  end

  def privacy
  end

  def faq
  end

  def pagecord_vs_hey_world
  end
end
