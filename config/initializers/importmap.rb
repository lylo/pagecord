# Public blog pages draw their own map, since the whole map is inlined on every
# page that uses it.
draw_blog_importmap = lambda do
  Rails.application.config.importmap_blog = Importmap::Map.new.draw(Rails.root.join("config/importmap.blog.rb"))
end

draw_blog_importmap.call

if Rails.application.config.enable_reloading
  reloader = Rails.application.config.file_watcher.new(
    [ Rails.root.join("config/importmap.blog.rb") ],
    Rails.root.join("app/javascript").to_s => %w[ js ]
  ) { draw_blog_importmap.call }
  Rails.application.reloaders << reloader
  Rails.application.reloader.to_run { reloader.execute_if_updated }
end
