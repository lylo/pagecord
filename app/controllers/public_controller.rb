class PublicController < ApplicationController
  layout "home"

  caches_page :terms, :privacy, :faq

  def terms
  end

  def privacy
  end

  def faq
  end
end
