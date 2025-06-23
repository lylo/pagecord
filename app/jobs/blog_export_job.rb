class BlogExportJob < ApplicationJob
  queue_as :default

  def perform(export_id)
    if export = Blog::Export.find(export_id)
      Rails.logger.info "Starting export for #{export.blog.subdomain} (ID: #{export.id})"
      export.perform
    end
  end
end
