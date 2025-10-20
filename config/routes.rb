require "sidekiq/web"

class SidekiqAdminConstraint
  def matches?(request)
    if current_user = User.kept.find(request.session[:user_id])
      ENV["ADMIN_USERNAME"] == current_user.blog.subdomain &&
      # FIXME this should be a password
      ENV["ADMIN_DELIVERY_EMAIL"] == current_user.blog.delivery_email
    else
      false
    end
  rescue
    false
  end
end

class PgHeroAdminConstraint
  def matches?(request)
    return false unless request.session[:user_id]
    user = User.kept.find_by(id: request.session[:user_id])
    user&.admin?
  end
end

module DomainConstraints
  def self.default_domain?(request)
    if Rails.env.test?
      [ "www.example.com", "lvh.me", "example.com" ].include?(request.host)
    else
      default_host = Rails.application.config.x.domain
      request.host == default_host || request.host == "www.#{default_host}"
    end
  end
end


module Constraints
  class RssFormat
    def matches?(request)
      request.format.rss?
    end
  end
end

Rails.application.routes.draw do
  # Helper method for subdomain redirects
  def subdomain_redirect(path = "/")
    ->(params, _req) do
      host = Rails.application.config.x.domain
      options = Rails.application.config.action_controller.default_url_options
      scheme = options[:protocol] || "https"
      port = options[:port] ? ":#{options[:port]}" : ""

      "#{scheme}://#{params[:name]}.#{host}#{port}#{path}"
    end
  end

  get "up", to: "rails/health#show", as: :rails_health_check
  get "verify_domain", to: "custom_domains#verify", as: :verify_custom_domain

  # PWA routes
  get "manifest", to: "rails/pwa#manifest", as: :pwa_manifest

  constraints SidekiqAdminConstraint.new do
    mount Sidekiq::Web, at: "/admin/sidekiq"
  end

  constraints PgHeroAdminConstraint.new do
    mount PgHero::Engine, at: "/admin/pghero"
  end

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  get "/404", to: "errors#not_found"
  get "/422", to: "errors#unacceptable"
  get "/500", to: "errors#internal_error"

  resources :signups, only: [ :index, :new, :create ] do
    get :thanks, on: :collection
  end

  namespace :billing do
    resources :paddle_events, only: [ :create ]
    post "/paddle/create_update_payment_method_transaction", to: "paddle#create_update_payment_method_transaction"
  end

  get "/login", to: "sessions#new"
  delete "/logout", to: "sessions#destroy"
  resources :sessions, only: [ :create ] do
    get :thanks, on: :collection
  end

  get "/verify/:token", to: "access_requests#verify", as: :verify_access_request

  namespace :app do
    resources :analytics, only: [ :index ]
    resources :posts, except: [ :show ], param: :token
    resources :pages, except: [ :show ], param: :token do
      member do
        post :set_as_home_page
      end
    end
    resource :home_page, only: [ :new, :create, :edit, :update, :destroy ]
    resources :settings, only: [ :index ]

    resource :onboarding, only: [ :show, :update ], path: "onboarding" do
      member do
        post :complete
      end
    end

    namespace :settings do
      resources :audience, only: [ :index ]
      resources :users, only: [ :update, :destroy ]
      resources :blogs, only: [ :index, :update ]
      resources :appearance, only: [ :index, :update ]
      resources :navigation_items, only: [ :index, :create, :update, :destroy ]
      resource :social_links, only: [ :update ]
      resources :email_subscribers, only: [ :index ]
      resources :email_change_requests, only: [ :create, :destroy ] do
        member do
          post :resend
        end
        collection do
          get "verify/:token", to: "email_change_requests#verify", as: :verify
        end
      end

      resources :exports

      resources :sender_email_addresses, only: [ :create, :destroy ] do
        collection do
          get "verify/:token", to: "sender_email_addresses#verify", as: :verify
        end
      end

      get "/account/edit", to: "account#edit"

      resources :subscriptions, only: [ :index, :destroy ] do
        get :thanks, on: :collection
        get :cancel_confirm, on: :collection
      end
    end

    resources :blogs do
      resource :avatar, only: [ :destroy ], controller: "blogs/avatars"

      resources :social_links, only: [ :new ], controller: "blogs/social_links"

      post :follow, to: "followings#create"
      delete :unfollow, to: "followings#destroy"
    end

    resources :followings, only: [ :index ]

    get "/account", to: "account#index"

    get "/feed", to: "feed#index"
    get "/feed/rss/:token", to: "feed#private_rss", as: :private_rss_feed, format: :rss

    root "posts#index"
  end

  get "/admin", to: "admin#index", as: :admin
  namespace :admin do
    resources :blogs, only: [ :index ]
    resources :analytics, only: [ :index ]
    resources :posts, only: [ :index ]
    resources :users, only: [ :show, :destroy, :new, :create ] do
      member do
        post :restore
      end
    end
  end

  constraints(->(request) { !DomainConstraints.default_domain?(request) }) do
    get "/robots.txt", to: "blogs/robots#show", as: :blog_robots, format: :text
    get "/sitemap.xml", to: "blogs/sitemaps#show", as: :blog_sitemap, format: :xml
    get "/", to: "blogs/posts#index", as: :blog_posts
    get "/posts", to: "blogs/posts#posts_list", as: :blog_posts_list
    get "/feed.xml", to: "blogs/posts#index", defaults: { format: :rss }, as: :blog_feed_xml
    get "/feed", to: "blogs/posts#index", defaults: { format: :rss }, as: :blog_feed
    get "/:name.rss", to: redirect("/feed.xml")

    post "/pv", to: "blogs/page_views#create", as: :blog_page_views

    namespace :api do
      post "embeds/bandcamp", to: "embeds#bandcamp"
    end

    get "/:slug", to: "blogs/posts#show", as: :blog_post

    resources :email_subscribers, controller: "blogs/email_subscribers", only: [ :create, :destroy ]

    get "/email_subscribers/:token/confirm", to: "blogs/email_subscribers/confirmations#show", as: :email_subscriber_confirmation
    get "/email_subscribers/:token/unsubscribe", to: "blogs/email_subscribers/unsubscribes#show", as: :email_subscriber_unsubscribe
    post "/email_subscribers/:token/unsubscribe", to: "blogs/email_subscribers/unsubscribes#create"
    post "/email_subscribers/:token/one_click_unsubscribe", to: "blogs/email_subscribers/unsubscribes#one_click", as: :email_subscriber_one_click_unsubscribe

    resources :posts, only: [], param: :token do
      resources :upvotes, only: [ :create ], module: :posts
      resources :replies, only: [ :new, :create ], module: :posts
    end

    # Catch-all for unmatched routes on blog domains
    match "*path", to: "blogs/posts#not_found", via: :all
  end

  constraints(DomainConstraints.method(:default_domain?)) do
    get "/sitemap.xml", to: "public#sitemap", as: :public_sitemap, format: :xml
    get "/robots.txt", to: "public#robots", as: :robots, format: :text
    get "/terms", to: "public#terms", as: :terms
    get "/privacy", to: "public#privacy", as: :privacy
    get "/faq", to: "public#faq", as: :faq
    get "/pagecord-vs-hey-world", to: "public#pagecord_vs_hey_world"
    get "/pagecord-vs-wordpress", to: "public#pagecord_vs_wordpress"
    get "/pagecord-vs-substack", to: "public#pagecord_vs_substack"
    get "/blogging-by-email", to: "public#blogging_by_email"

    get "/@:name", to: redirect("/%{name}")

    get "/:name.rss", to: redirect(subdomain_redirect("/feed.xml")),
        constraints: { name: /(?!rails|admin|app|api)[a-z0-9]+/i }, defaults: { format: :rss }

    get "/:name(/*path)", to: redirect { |params, _req|
      path = params[:path] ? "/#{params[:path]}" : "/"
      subdomain_redirect(path).call(params, _req)
    }, constraints: { name: /(?!rails|admin|app|api)[a-z0-9]+/i }
  end

  direct :rails_public_blob do |blob|
    if ENV.fetch("ACTIVE_STORAGE_ASSET_HOST", false) && blob&.key
      File.join(ENV.fetch("ACTIVE_STORAGE_ASSET_HOST"), blob.key)
    else
      route =
        if blob.is_a?(ActiveStorage::Variant) || blob.is_a?(ActiveStorage::VariantWithRecord)
          :rails_representation
        else
          :rails_blob
        end

      route_for(route, blob)
    end
  end

  root "home#index"
end
