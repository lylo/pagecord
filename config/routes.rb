require "sidekiq/web"

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
  get "verify_domain", to: "custom_domains/verifications#show", as: :custom_domain_verification

  # PWA routes
  get "manifest", to: "rails/pwa#manifest", as: :pwa_manifest, defaults: { format: :json }, constraints: { format: :json }

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  get "/404", to: "errors#not_found"
  get "/422", to: "errors#unacceptable"
  get "/429", to: "errors#too_many_requests"
  get "/500", to: "errors#internal_error"

  namespace :billing do
    resources :paddle_events, only: [ :create ]

    namespace :paddle do
      resource :payment_method_transaction, only: [ :create ]
    end
  end

  # The apex is the only host this app serves. www used to serve a full second
  # copy, which meant uploads failed silently there: only the apex is in the R2
  # CORS allowlist, and that policy lives in the Cloudflare dashboard rather
  # than in git, so the drift was invisible. Redirect rather than widen CORS.
  constraints(->(request) { request.host == "www.#{Rails.application.config.x.domain}" }) do
    match "(*path)", to: redirect(host: Rails.application.config.x.domain), via: :all
  end

  constraints(DomainConstraints.method(:default_domain?)) do
    constraints AdminConstraint.new do
      mount Sidekiq::Web, at: "/admin/sidekiq"
      mount PgHero::Engine, at: "/admin/pghero"
    end

    resources :signups, only: [ :index, :new, :create ]
    namespace :signups do
      resource :thanks, only: [ :show ], controller: "thanks"
    end

    get "/login", to: "sessions#new"
    delete "/logout", to: "sessions#destroy"
    resources :sessions, only: [ :create ]
    namespace :sessions do
      resource :thanks, only: [ :show ], controller: "thanks"
      resource :closed, only: [ :show ], controller: "closed"
    end

    resources :password_resets, only: [ :new, :create, :edit, :update ], param: :token
    namespace :password_resets do
      resource :thanks, only: [ :show ], controller: "thanks"
    end

    get "/verify/:token", to: "access_requests/verifications#show", as: :access_request_verification

    namespace :app do
      resource :upgrade_banner, only: [ :destroy ]
      resources :analytics, only: [ :index ]
      namespace :posts do
        resource :trash, only: [ :show, :create, :destroy ], controller: "trash"
        resource :details, only: [ :create, :destroy ], controller: "details"
      end
      resources :posts, param: :token do
        resource :broadcast, only: [ :create ], controller: "posts/broadcasts" do
          resource :test, only: [ :create ], controller: "posts/broadcasts/tests"
        end
        resource :open_graph_image, only: [ :destroy ], controller: "posts/open_graph_images"
        resource :restoration, only: [ :create ], controller: "posts/restorations"
        resources :comments, only: [ :index ], controller: "comments"
      end

      namespace :pages do
        resource :trash, only: [ :show, :create, :destroy ], controller: "trash"
        resource :sort_order, only: :update
      end
      resources :pages, except: [ :show ], param: :token do
        resource :restoration, only: [ :create ], controller: "pages/restorations"
        resource :home_page, only: [ :create ], controller: "pages/home_pages"
      end
      resource :home_page, only: [ :new, :create, :edit, :update, :destroy ]
      resources :comments, only: [ :index, :show, :destroy ] do
        resource  :approval, only: [ :create ], controller: "comments/approvals"
        resource  :closure,  only: [ :create, :destroy ], controller: "comments/closures"
        resources :replies,  only: [ :create, :destroy ], controller: "comments/replies"
      end
      resources :settings, only: [ :index ]

      resource :onboarding, only: [ :show, :update ], path: "onboarding" do
        resource :completion, only: [ :create ], controller: "onboardings/completions"
        resource :theme, only: [ :update ], controller: "onboardings/themes"
      end

      namespace :settings do
        resource :about, only: [ :show, :update ], controller: "about"
        resource :audience, only: :show, controller: "audience"
        resources :subscribers, only: [ :index ]
        resources :users, only: [ :update, :destroy ]
        resource :blog, only: [ :show, :update ], controller: "blogs"
        resource :appearance, only: [ :show, :update ], controller: "appearance"
        resources :theme_garden, only: [ :index ] do
          resource :preview, only: [ :show ], controller: "theme_garden/previews"
          resource :application, only: [ :create ], controller: "theme_garden/applications"
        end
        resources :navigation_items, only: [ :index, :create, :update, :destroy ]
        resources :email_change_requests, only: [ :create, :destroy ] do
          resource :resend, only: [ :create ], controller: "email_change_requests/resends"
        end
        namespace :email_change_requests do
          get "verify/:token", to: "verifications#show", as: :verification
        end

        resource :custom_code, only: [ :show, :update ], controller: "custom_code"
        resource :api, only: [ :show, :create, :destroy ], controller: "api"
        resources :exports

        resources :sender_email_addresses, only: [ :create, :destroy ]
        namespace :sender_email_addresses do
          get "verify/:token", to: "verifications#show", as: :verification
        end

        resource :account, only: :edit, controller: "account"

        resources :subscriptions, only: [ :index ]
        namespace :subscriptions do
          resource :thanks, only: [ :show ], controller: "thanks"
          resource :cancellation, only: [ :new, :create ]
          resource :plan, only: [ :update ]
          resource :resumption, only: [ :create ]
        end
        resource :paddle_invoices, only: :show, controller: "subscriptions/paddle_invoices"
      end

      namespace :blogs do
        resource :trash, only: [ :show, :destroy ], controller: "trash"
      end

      resources :blogs, only: [ :index, :new, :create, :destroy ] do
        resource :selection, only: [ :create ], controller: "blogs/selections"
        resource :restoration, only: [ :create ], controller: "blogs/restorations"
        resource :avatar, only: [ :destroy ], controller: "blogs/avatars"
      end

      root "posts#index"

      # The blog settings page was /app/settings/blogs before it became a
      # singular resource. Keep old bookmarks and support links working.
      get "/settings/blogs", to: redirect("/app/settings/blog")
    end

    get "/admin", to: redirect("/admin/users"), as: :admin

    namespace :admin do
      namespace :theme_templates do
        resources :fixtures, only: :index
      end
      resources :theme_templates
      resources :analytics, only: [ :index ]
      resources :posts, only: [ :index ]
      resources :deliverability_issues, only: [ :index, :destroy ],
                param: :email, constraints: { email: /[^\/]+/ }
      resource :deliverability_purge, only: [ :create ]
      resources :users, only: [ :index, :show, :destroy, :new, :create, :update ] do
        resource :restoration, only: [ :create ], controller: "users/restorations"
        resource :subscription, only: [ :update ]
        resource :verification_email, only: [ :create ]
        resource :spotlight_exclusion, only: [ :create, :destroy ]
      end
      namespace :moderation do
        root to: redirect("/admin/moderation/blogs")

        resources :content, only: [ :index, :show ] do
          resource :dismissal, only: [ :create ], controller: "content/dismissals"
          resource :discard, only: [ :create ], controller: "content/discards"
        end

        resources :blogs, only: [ :index ] do
          resource :review, only: [ :create ], controller: "blogs/reviews"
          resource :spam_confirmation, only: [ :create ], controller: "blogs/spam_confirmations"
        end
      end
    end

    get "/sitemap.xml", to: "public/sitemaps#show", as: :public_sitemap, format: :xml
    get "/robots.txt", to: "public/robots#show", as: :robots, format: :text
    get "/llms.txt", to: "public/llms#show", as: :llms_txt, format: :text
    get "/pricing", to: redirect("/#pricing"), as: :pricing
    MARKETING_PAGES.each_key do |slug|
      get "/#{slug}", to: "public/pages#show", as: slug.tr("-", "_"),
          defaults: { slug: slug }
    end

    get "/supporters", to: "home/supporters#show"
    get "/spotlight", to: "home/spotlight#show"
    get "/spotlight/trending.xml", to: "home/spotlight#show", defaults: { format: :rss }, as: :spotlight_trending_feed
    get "/shuffle", to: "home/shuffle#show"

    get "/@:name", to: redirect("/%{name}")

    get "/:name.rss", to: redirect(subdomain_redirect("/feed.xml")),
        constraints: { name: /(?!rails|admin|app|api)[a-z0-9]+/i }, defaults: { format: :rss }

    get "/:name(/*path)", to: redirect { |params, _req|
      path = params[:path] ? "/#{ActionDispatch::Journey::Router::Utils.escape_path(params[:path])}" : "/"
      subdomain_redirect(path).call(params, _req)
    }, constraints: { name: /(?!rails|admin|app|api)[a-z0-9]+/i }
  end


  constraints(DomainConstraints.method(:api_domain?)) do
    scope module: :api do
      resources :posts, only: [ :index, :show, :create, :update, :destroy ], param: :token
      resources :pages, only: [ :index, :show, :create, :update, :destroy ], param: :token
      resource :home_page, only: [ :show, :create, :update, :destroy ]
      resources :attachments, only: [ :create ]
      # The Micropub spec mandates a single endpoint, so these two stay as they are.
      post "/micropub", to: "micropub#create"
      get "/micropub", to: "micropub#query", as: nil
      post "/micropub/media", to: "micropub/media#create"
    end
  end

  # Available on every domain, so embeds also resolve when previewing a draft in the app.
  namespace :api do
    namespace :embeds do
      resource :bandcamp, only: [ :create ], controller: "bandcamp"
    end
  end

  constraints(->(request) { !DomainConstraints.default_domain?(request) }) do
    get "/robots.txt", to: "blogs/robots#show", as: :blog_robots, format: :text
    get "/sitemap.xml", to: "blogs/sitemaps#show", as: :blog_sitemap, format: :xml
    get "/", to: "blogs/posts#index", as: :blog_posts
    get "/posts", to: "blogs/posts/lists#index", as: :blog_posts_list
    get "/search", to: "blogs/searches#show", as: :blog_search
    post "/access", to: "blogs/access#create", as: :blog_access
    get "/feed.xml", to: "blogs/posts#index", defaults: { format: :rss }, as: :blog_feed_xml
    get "/feed", to: "blogs/posts#index", defaults: { format: :rss }, as: :blog_feed
    get "/:name.rss", to: redirect("/feed.xml")
    get "/rss", to: redirect("/feed.xml")

    post "/pv", to: "blogs/page_views#create", as: :blog_page_views

    get "/posts/embedded", to: "blogs/embedded_posts#index", as: :blog_embedded_posts
    get "/posts/:slug", to: "blogs/posts#show"

    get "/:slug", to: "blogs/posts#show", as: :blog_post

    resources :email_subscribers, controller: "blogs/email_subscribers", only: [ :create, :destroy ]
    resources :contact_messages, controller: "blogs/contact_messages", only: [ :create ]

    get "/email_subscribers/:token/confirm", to: "blogs/email_subscribers/confirmations#show", as: :email_subscriber_confirmation
    get "/email_subscribers/:token/unsubscribe", to: "blogs/email_subscribers/unsubscribes#show", as: :email_subscriber_unsubscribe
    post "/email_subscribers/:token/unsubscribe", to: "blogs/email_subscribers/unsubscribes#create"
    post "/email_subscribers/:token/one_click_unsubscribe", to: "blogs/email_subscribers/unsubscribes#one_click", as: :email_subscriber_one_click_unsubscribe

    get "/upvotes/statuses", to: "blogs/posts/upvotes/statuses#show", as: :upvotes_statuses

    resources :posts, only: [], param: :token do
      resources :upvotes, only: [ :create ], module: "blogs/posts"
      resources :replies, only: [ :new, :create ], module: "blogs/posts" do
        get :sent, on: :collection
      end
      resources :comments, only: [ :index, :create ], module: "blogs/posts"
    end

    get "/:year/:month/:day/:slug", to: "blogs/posts#show", as: :blog_dated_post,
        constraints: { year: /\d{4}/, month: /\d{2}/, day: /\d{2}/ }
    # Accept inbound Blogger routes
    get "/:year/:month/:slug", to: "blogs/posts#show",
        constraints: { year: /\d{4}/, month: /\d{2}/ }
    get "/:prefix/:slug", to: "blogs/posts#show", as: :blog_prefixed_post

    # Catch-all for unmatched routes on blog domains
    match "*path", to: "blogs/posts#not_found", via: :all
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
