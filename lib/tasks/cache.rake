namespace :cache do
  desc "Expire the cache for the home page"
  task expire_static_pages: :environment do
    ActionController::Base.new.expire_page("/")
    ActionController::Base.new.expire_page("/faq")
    ActionController::Base.new.expire_page("/terms")
    ActionController::Base.new.expire_page("/privacy")
    ActionController::Base.new.expire_page("/pagecord-vs-hey-world")
    ActionController::Base.new.expire_page("/pagecord-vs-wordpress")
    ActionController::Base.new.expire_page("/pagecord-vs-substack")
  end
end
