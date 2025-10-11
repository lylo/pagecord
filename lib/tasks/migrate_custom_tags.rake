# frozen_string_literal: true

namespace :custom_tags do
  desc "Migrate custom tag syntax from space-separated to pipe-separated (dry-run by default, use APPLY=true to execute)"
  task migrate_to_pipes: :environment do
    apply_changes = ENV["APPLY"] == "true"
    subdomains = ENV["SUBDOMAINS"]&.split(",")&.map(&:strip)

    if subdomains.blank?
      puts "ERROR: Please provide SUBDOMAINS"
      puts "Usage: rake custom_tags:migrate_to_pipes SUBDOMAINS=joel,alice"
      puts "       rake custom_tags:migrate_to_pipes SUBDOMAINS=joel,alice APPLY=true"
      exit 1
    end

    blogs = Blog.where(subdomain: subdomains)
    puts "Found #{blogs.count} blogs: #{blogs.pluck(:subdomain).join(', ')}"

    pages = Post.where(blog: blogs, is_page: true)
    puts "Found #{pages.count} pages to check\n\n"

    changes = []

    pages.each do |page|
      next unless page.content.to_plain_text.include?("{{")

      original = page.content.to_s
      updated = convert_syntax(original)

      if original != updated
        changes << {
          blog: page.blog.subdomain,
          page: page.title || page.slug,
          original: original,
          updated: updated,
          post: page
        }
      end
    end

    if changes.empty?
      puts "✓ No changes needed!"
      exit
    end

    # Show preview
    changes.each do |change|
      puts "=" * 80
      puts "Blog: #{change[:blog]} | Page: #{change[:page]}"
      puts "-" * 80
      puts "BEFORE:"
      puts change[:original]
      puts "\nAFTER:"
      puts change[:updated]
      puts
    end

    puts "=" * 80
    puts "Found #{changes.count} page(s) to update"

    if apply_changes
      changes.each do |change|
        change[:post].update!(content: change[:updated])
      end
      puts "✓ Applied #{changes.count} changes"
    else
      puts "\n⚠️  DRY RUN - No changes applied"
      puts "To apply changes, run: rake custom_tags:migrate_to_pipes SUBDOMAINS=#{subdomains.join(',')} APPLY=true"
    end
  end

  def convert_syntax(content)
    # Convert {{ posts tag: X limit: Y }} to {{ posts | tag: X | limit: Y }}
    content.gsub(/\{\{\s*(posts(?:_by_year)?|tags|email_subscription)\s+([^}]+)\}\}/) do |match|
      tag_name = Regexp.last_match(1)
      params = Regexp.last_match(2).strip

      # Skip if already has pipes or has no parameters
      next match if params.include?("|") || params.empty?

      # Skip tags that don't take parameters
      next match if tag_name == "tags" || tag_name == "email_subscription"

      # Split parameters and rejoin with pipes
      parts = params.scan(/(\w+):\s*([^}]+?)(?=\s+\w+:|$)/)
      param_strings = parts.map { |key, val| "#{key}: #{val.strip}" }

      "{{ #{tag_name} | #{param_strings.join(' | ')} }}"
    end
  end
end
