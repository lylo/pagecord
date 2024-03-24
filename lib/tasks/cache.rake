namespace :cache do
  desc "Expire the cache for the home page"
  task expire_static_pages: :environment do
    ActionController::Base.new.expire_page("/")
    ActionController::Base.new.expire_page("/faq")
    ActionController::Base.new.expire_page("/terms")
    ActionController::Base.new.expire_page("/privacy")
  end
end
