namespace :theme_templates do
  desc "Count the blogs on each theme template version, discarded ones included, to see which stylesheets are still in use"
  task usage: :environment do
    counts = Blog.where.not(theme_template_id: nil).group(:theme_template_id, :theme_template_version).count

    ThemeTemplate.ordered.each do |template|
      versions = (template.stylesheet_versions + counts.keys.filter_map { |id, version| version if id == template.id }).uniq.sort

      versions.each do |version|
        status = template.stylesheet?(version) ? ("(current)" if version == template.version) : "MISSING"
        puts [ "#{template.stylesheet(version)}.css", status, counts[[ template.id, version ]] || 0 ].compact.join(" ")
      end
    end
  end
end
