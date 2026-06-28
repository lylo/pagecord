session_options = {
  key: "_pagecord_v3",
  expire_after: 1.year
}

Rails.application.config.session_store :cookie_store, **session_options
