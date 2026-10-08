namespace :theme_templates do
  desc "Report how this environment's theme templates differ from the fixtures. Usage: bin/rails \"theme_templates:drift[novella]\""
  task :drift, [ :theme ] => :environment do |_task, args|
    each_theme_fixture(args[:theme]) do |name, template, changes, only_here, only_fixture|
      if template.nil?
        puts "#{name}: missing here"
      elsif changes.empty? && only_here.empty? && only_fixture.empty?
        puts "#{name}: in sync"
      else
        puts "#{name}:"
        changes.each { |attribute, (here, fixture)| puts "  #{attribute}: #{here.inspect} -> #{fixture.inspect}" }
        only_here.each { |line| puts "  here     #{line}" }
        only_fixture.each { |line| puts "  fixture  #{line}" }
      end
    end
  end

  desc "Update this environment's theme templates from the fixtures, creating any that are missing. Run theme_templates:drift first. Usage: DRY_RUN=true bin/rails \"theme_templates:sync[novella]\""
  task :sync, [ :theme ] => :environment do |_task, args|
    dry_run = ENV["DRY_RUN"] == "true"

    puts "=== DRY RUN - nothing will be written ===" if dry_run

    each_theme_fixture(args[:theme]) do |name, template, changes, only_here, only_fixture, attrs|
      if template.nil?
        if dry_run
          puts "#{name}: would create"
        elsif (template = ThemeTemplate.create(attrs)).persisted?
          puts "#{name}: created"
        else
          puts "#{name}: failed, #{template.errors.full_messages.to_sentence}"
        end
        next
      end

      if changes.empty? && only_here.empty? && only_fixture.empty?
        puts "#{name}: unchanged"
        next
      end

      if dry_run
        puts "#{name}: would update"
      else
        backup = Rails.root.join("tmp", "#{name.parameterize}-theme-backup.css")
        File.write(backup, template.custom_css)

        if template.update(attrs)
          puts "#{name}: updated, backup at #{backup}"
        else
          puts "#{name}: failed, #{template.errors.full_messages.to_sentence}"
          next
        end
      end

      changes.each { |attribute, (here, fixture)| puts "  #{attribute}: #{here.inspect} -> #{fixture.inspect}" }
      only_here.each { |line| puts "  replaced  #{line}" }
    end
  end
end

# Compares CSS as line sets rather than whole strings, so reordering and blank
# lines are ignored and only genuinely absent rules are reported.
def each_theme_fixture(theme = nil)
  fixtures = YAML.load_file(Rails.root.join("test/fixtures/theme_templates.yml"))

  if theme.present?
    fixtures = fixtures.select { |key, attrs| [ key, attrs["name"] ].any? { |candidate| candidate.casecmp?(theme) } }
    abort "No theme template named #{theme}" if fixtures.empty?
  end

  fixtures.each_value do |attrs|
    name = attrs["name"]
    template = ThemeTemplate.find_by(name:)
    changes = template ? attribute_changes(template, attrs) : {}
    fixture_lines = significant_css_lines(attrs["custom_css"])
    live_lines = significant_css_lines(template&.custom_css)

    yield name, template, changes, live_lines - fixture_lines, fixture_lines - live_lines, attrs
  end
end

def attribute_changes(template, attrs)
  attrs.except("custom_css")
       .reject { |attribute, value| template[attribute].to_s == value.to_s }
       .to_h { |attribute, value| [ attribute, [ template[attribute], value ] ] }
end

def significant_css_lines(css)
  css.to_s.lines.map(&:strip).reject(&:empty?)
end
