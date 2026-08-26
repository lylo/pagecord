require "middleware/bot_error_filter"
require "middleware/redirect_trailing_slash"

# Outermost, so bot noise is answered before error tracking ever sees it.
Rails.application.config.middleware.insert(0, BotErrorFilter)

# Early, so trailing slashes are redirected before routing and caching.
Rails.application.config.middleware.insert_before(Rack::Runtime, RedirectTrailingSlash)
