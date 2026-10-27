namespace :theme_templates do
  desc "Count the blogs on each theme template version, to see which stylesheets are still in use"
  task usage: :environment do
    counts = Blog.kept.with_kept_user.where.not(theme_template_id: nil).group(:theme_template_id, :theme_template_version).count

    ThemeTemplate.ordered.each do |template|
      template.stylesheet_versions.each do |version|
        current = version == template.version ? " (current)" : ""
        puts "#{template.stylesheet(version)}.css#{current}: #{counts[[ template.id, version ]] || 0}"
      end
    end
  end
end
