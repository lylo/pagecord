# The __Host- prefix makes browsers refuse this cookie unless it is Secure,
# path "/", and carries no Domain attribute. A blog subdomain therefore cannot
# write a cookie that reaches the app, which closes the cookie tossing route to
# session fixation now that customers can run their own JavaScript on
# *.pagecord.com. It requires the Secure flag, so it only applies where SSL is
# enforced – development over plain HTTP keeps the unprefixed name.
session_options = {
  key: Rails.application.config.force_ssl ? "__Host-pagecord_session" : "_pagecord_v3",
  expire_after: 1.year
}

Rails.application.config.session_store :cookie_store, **session_options
