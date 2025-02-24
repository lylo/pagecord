class BlogExportJob < ApplicationJob
  queue_as :default

  def perform(export_id)
    export = Blog::Export.find(export_id)
    export.perform
  end
end
