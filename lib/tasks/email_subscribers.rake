require "csv"

namespace :email_subscribers do
  desc "Import confirmed subscribers from a CSV (headers: email, created_at, country — only email is required). Every row is imported as a confirmed subscriber, so remove unsubscribed/deleted contacts from the file first. Usage: DRY_RUN=true bin/rails \"email_subscribers:import[blog_subdomain,path/to/subscribers.csv]\""
  task :import, [ :blog_subdomain, :csv_path ] => :environment do |_task, args|
    blog = Blog.find_by(subdomain: args[:blog_subdomain])
    unless blog
      puts "Blog not found: #{args[:blog_subdomain]}"
      exit 1
    end

    csv_path = args[:csv_path]
    unless csv_path.present? && File.exist?(csv_path)
      puts "CSV file not found: #{csv_path}"
      exit 1
    end

    dry_run = ENV["DRY_RUN"] == "true"
    puts "=== DRY RUN - no records will be created ===" if dry_run

    rows = CSV.read(csv_path, headers: true, encoding: "bom|utf-8", header_converters: ->(header) { header&.strip })
    unless rows.headers.include?("email")
      puts "CSV must have an 'email' header. Found: #{rows.headers.join(", ")}"
      exit 1
    end

    puts "Found #{rows.size} rows to import for blog '#{blog.subdomain}'"

    imported_count = 0
    skipped_count = 0
    failed_count = 0

    rows.each do |row|
      email = row["email"]&.strip

      if email.blank?
        puts "Failed: row has no email"
        failed_count += 1
        next
      end

      if blog.email_subscribers.where("LOWER(email) = LOWER(?)", email).exists?
        puts "Skipped (already subscribed): #{email}"
        skipped_count += 1
        next
      end

      subscribed_at = begin
        row["created_at"].present? ? Time.parse(row["created_at"]) : Time.current
      rescue ArgumentError
        Time.current
      end

      subscriber = blog.email_subscribers.new(
        email: email,
        country: row["country"]&.strip.presence,
        confirmed_at: subscribed_at,
        created_at: subscribed_at,
        updated_at: Time.current
      )

      if subscriber.valid?
        subscriber.save unless dry_run
        imported_count += 1
      else
        puts "Failed: #{email} (#{subscriber.errors.full_messages.join(", ")})"
        failed_count += 1
      end
    end

    puts "\n=== IMPORT SUMMARY ==="
    puts "Subscribers imported: #{imported_count}"
    puts "Subscribers skipped: #{skipped_count}" if skipped_count > 0
    puts "Subscribers failed: #{failed_count}" if failed_count > 0
    puts "====================="
  end

  desc "Delete unconfirmed email subscribers older than 1 week"
  task cleanup_unconfirmed: :environment do
    unconfirmed = EmailSubscriber.unconfirmed.where("created_at < ?", 1.week.ago)
    count = unconfirmed.count

    if count > 0
      Rails.logger.info "Deleting #{count} unconfirmed email subscribers older than 1 week"
      unconfirmed.destroy_all
      Rails.logger.info "Successfully deleted #{count} unconfirmed email subscribers"
    else
      Rails.logger.info "No unconfirmed email subscribers to clean up"
    end
  end
end
