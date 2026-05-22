class BlogExportJob < ApplicationJob
  queue_as :default

  def perform(export_id)
    export = Blog::Export.find(export_id)

    with_sentry_context(user: export.blog.user, blog: export.blog) do
      Rails.logger.info "Starting export for #{export.blog.subdomain} (ID: #{export.id})"
      export.perform
    end
  end
end
