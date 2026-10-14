# Public blog pages and the marketing pages draw their own maps, since the whole
# map is inlined on every page that uses it.
maps = { importmap_blog: "config/importmap.blog.rb", importmap_home: "config/importmap.home.rb" }

draw_importmaps = lambda do
  maps.each { |name, path| Rails.application.config.public_send("#{name}=", Importmap::Map.new.draw(Rails.root.join(path))) }
end

draw_importmaps.call

if Rails.application.config.enable_reloading
  reloader = Rails.application.config.file_watcher.new(
    maps.values.map { |path| Rails.root.join(path) },
    Rails.root.join("app/javascript").to_s => %w[ js ]
  ) { draw_importmaps.call }
  Rails.application.reloaders << reloader
  Rails.application.reloader.to_run { reloader.execute_if_updated }
end
