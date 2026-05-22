class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  private

    def with_sentry_context(user: nil, blog: nil)
      unless Sentry.initialized?
        return yield
      end

      Sentry.with_scope do |scope|
        scope.set_user(id: user.id) if user
        scope.set_context("blog", { id: blog.id, subdomain: blog.subdomain }) if blog
        yield
      end
    end
end
