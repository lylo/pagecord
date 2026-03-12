namespace :activestorage do
  desc "Summary statistics for ActiveStorage blobs"
  task audit: :environment do
    total = ActiveStorage::Blob.count
    attached = ActiveStorage::Blob.joins(:attachments).distinct.count
    unattached = ActiveStorage::Blob.unattached.count

    puts "ActiveStorage Audit"
    puts "=" * 60
    puts "Total blobs:       #{total}"
    puts "Attached:          #{attached}"
    puts "Unattached:        #{unattached}"
    puts ""

    total_bytes = ActiveStorage::Blob.sum(:byte_size)
    orphan_bytes = ActiveStorage::Blob.unattached.sum(:byte_size)
    puts "Total storage:     #{ActiveSupport::NumberHelper.number_to_human_size(total_bytes)}"
    puts "Orphan storage:    #{ActiveSupport::NumberHelper.number_to_human_size(orphan_bytes)}"
    puts ""

    puts "By content type:"
    ActiveStorage::Blob.group(:content_type).order("count_all DESC").count.each do |type, count|
      bytes = ActiveStorage::Blob.where(content_type: type).sum(:byte_size)
      puts "  %-30s %5d  %s" % [ type, count, ActiveSupport::NumberHelper.number_to_human_size(bytes) ]
    end
    puts ""

    puts "By record type:"
    ActiveStorage::Attachment.group(:record_type).order("count_all DESC").count.each do |type, count|
      puts "  %-30s %5d" % [ type, count ]
    end
  end

  desc "List unattached blobs older than DAYS days (default 30)"
  task orphans: :environment do
    age = (ENV.fetch("DAYS", 30).to_i).days.ago
    orphans = ActiveStorage::Blob.unattached.where("active_storage_blobs.created_at < ?", age).order(created_at: :desc)
    count = orphans.count

    if count == 0
      puts "No unattached blobs older than #{ENV.fetch("DAYS", 30)} days found."
      next
    end

    puts "Unattached blobs: #{count}"
    puts "%-8s %-30s %-25s %12s  %s" % [ "ID", "Filename", "Content Type", "Size", "Created" ]
    puts "-" * 100

    orphans.find_each do |blob|
      puts "%-8d %-30s %-25s %12s  %s" % [
        blob.id,
        blob.filename.to_s.truncate(28),
        blob.content_type.to_s.truncate(23),
        ActiveSupport::NumberHelper.number_to_human_size(blob.byte_size),
        blob.created_at.strftime("%Y-%m-%d %H:%M")
      ]
    end

    total_bytes = orphans.sum(:byte_size)
    puts "-" * 100
    puts "Total: #{count} blobs, #{ActiveSupport::NumberHelper.number_to_human_size(total_bytes)}"
  end

  namespace :orphans do
    desc "Download unattached blobs older than DAYS days (default 30) to OUTPUT_DIR"
    task download: :environment do
      output_dir = ENV.fetch("OUTPUT_DIR", Rails.root.join("tmp/orphaned_blobs").to_s)
      FileUtils.mkdir_p(output_dir)

      age = (ENV.fetch("DAYS", 30).to_i).days.ago
      orphans = ActiveStorage::Blob.unattached.where("active_storage_blobs.created_at < ?", age).order(:id)
      count = orphans.count

      if count == 0
        puts "No unattached blobs older than #{ENV.fetch("DAYS", 30)} days to download."
        next
      end

      puts "Downloading #{count} unattached blobs to #{output_dir}"

      downloaded = 0
      errors = 0

      orphans.find_each do |blob|
        filename = "#{blob.id}_#{blob.filename}"
        filepath = File.join(output_dir, filename)

        begin
          blob.open do |tempfile|
            FileUtils.cp(tempfile.path, filepath)
          end
          downloaded += 1
          print "."
        rescue => e
          errors += 1
          puts "\nFailed to download blob #{blob.id} (#{blob.key}): #{e.message}"
        end
      end

      puts "\nDone. Downloaded: #{downloaded}, Errors: #{errors}"
      puts "Files saved to: #{output_dir}"
    end

    desc "Analyze why blobs are orphaned (traces back to post/blog/export)"
    task analyze: :environment do
      age = (ENV.fetch("DAYS", 30).to_i).days.ago

      # 1. Dangling attachments — attachment record exists but parent is gone
      dangling = ActiveStorage::Attachment.where.not(
        record_type: "ActionText::RichText"
      ).left_joins(:blob).where("active_storage_blobs.created_at < ?", age).select do |att|
        !att.record_type.constantize.exists?(att.record_id)
      end

      dangling_at = ActiveStorage::Attachment.where(
        record_type: "ActionText::RichText"
      ).left_joins(:blob).where("active_storage_blobs.created_at < ?", age).select do |att|
        rich_text = ActionText::RichText.find_by(id: att.record_id)
        if rich_text.nil?
          true
        else
          !rich_text.record_type.constantize.exists?(rich_text.record_id)
        end
      end

      all_dangling = dangling + dangling_at

      puts "Orphan Analysis (blobs older than #{ENV.fetch("DAYS", 30)} days)"
      puts "=" * 100

      if all_dangling.any?
        puts ""
        puts "DANGLING ATTACHMENTS (attachment record exists, parent deleted)"
        puts "These are safe to purge — the owning record no longer exists."
        puts ""
        puts "%-8s %-22s %-8s %-10s %-25s %10s  %s" % [ "Blob ID", "Record Type", "Rec ID", "Status", "Filename", "Size", "Created" ]
        puts "-" * 100

        dangling_bytes = 0
        all_dangling.each do |att|
          blob = att.blob
          next unless blob

          status = if att.record_type == "ActionText::RichText"
            rt = ActionText::RichText.find_by(id: att.record_id)
            rt.nil? ? "no rich_text" : "no #{rt.record_type.underscore}"
          else
            "no #{att.record_type.underscore}"
          end

          dangling_bytes += blob.byte_size
          puts "%-8d %-22s %-8d %-10s %-25s %10s  %s" % [
            blob.id,
            att.record_type.truncate(20),
            att.record_id,
            status.truncate(10),
            blob.filename.to_s.truncate(23),
            ActiveSupport::NumberHelper.number_to_human_size(blob.byte_size),
            blob.created_at.strftime("%Y-%m-%d")
          ]
        end

        puts "-" * 100
        puts "Subtotal: #{all_dangling.size} blobs, #{ActiveSupport::NumberHelper.number_to_human_size(dangling_bytes)}"
      else
        puts ""
        puts "No dangling attachments found."
      end

      # 2. Fully unattached blobs — no attachment record at all
      unattached = ActiveStorage::Blob.unattached.where("active_storage_blobs.created_at < ?", age).order(created_at: :desc)
      unattached_count = unattached.count

      puts ""
      if unattached_count > 0
        puts "UNATTACHED BLOBS (no attachment record — likely failed or abandoned uploads)"
        puts ""

        by_type = unattached.reorder("").group(:content_type).order("count_all DESC").count
        by_type.each do |type, count|
          bytes = unattached.reorder("").where(content_type: type).sum(:byte_size)
          puts "  %-30s %5d  %s" % [ type, count, ActiveSupport::NumberHelper.number_to_human_size(bytes) ]
        end

        total_bytes = unattached.sum(:byte_size)
        puts ""
        puts "Subtotal: #{unattached_count} blobs, #{ActiveSupport::NumberHelper.number_to_human_size(total_bytes)}"
      else
        puts "No unattached blobs found."
      end
    end

    desc "Purge unattached blobs older than DAYS days (default 30, CONFIRM=true to execute)"
    task purge: :environment do
      age = (ENV.fetch("DAYS", 30).to_i).days.ago
      orphans = ActiveStorage::Blob.unattached.where("active_storage_blobs.created_at < ?", age).order(:id)
      count = orphans.count

      if count == 0
        puts "No unattached blobs older than #{ENV.fetch("DAYS", 30)} days to purge."
        next
      end

      total_bytes = orphans.sum(:byte_size)
      puts "#{count} unattached blobs, #{ActiveSupport::NumberHelper.number_to_human_size(total_bytes)}"

      unless ENV["CONFIRM"] == "true"
        puts "Dry run. Set CONFIRM=true to purge."
        next
      end

      purged = 0
      orphans.find_each do |blob|
        blob.purge
        purged += 1
        print "."
      end

      puts "\nPurged #{purged} blobs."
    end
  end

  namespace :actiontext do
    desc "Find zombie attachments (attached to ActionText but missing from body SGIDs)"
    task check: :environment do
      zombies = []

      ActionText::RichText.joins(:embeds_attachments).distinct.includes(embeds_attachments: :blob).find_each do |rich_text|
        next unless rich_text.body.present?

        doc = Nokogiri::HTML::DocumentFragment.parse(rich_text.body.to_html)
        sgids_in_body = doc.css("action-text-attachment[sgid]").map { |node| node["sgid"] }.to_set

        rich_text.embeds_attachments.each do |attachment|
          blob = attachment.blob
          next if sgids_in_body.include?(blob.attachable_sgid)

          zombies << {
            rich_text_id: rich_text.id,
            record_type: rich_text.record_type,
            record_id: rich_text.record_id,
            blob_id: blob.id,
            filename: blob.filename.to_s,
            content_type: blob.content_type,
            byte_size: blob.byte_size
          }
        end
      end

      if zombies.empty?
        puts "No zombie attachments found. All ActionText embeds match their body SGIDs."
        next
      end

      puts "Zombie attachments: #{zombies.size}"
      puts "These blobs are attached to ActionText records but their SGIDs"
      puts "do not appear in the body. They will be orphaned on next save."
      puts ""
      puts "%-6s %-20s %-8s %-8s %-25s %-20s %10s" % [ "RT ID", "Record", "Rec ID", "Blob ID", "Filename", "Content Type", "Size" ]
      puts "-" * 110

      zombies.each do |z|
        puts "%-6d %-20s %-8d %-8d %-25s %-20s %10s" % [
          z[:rich_text_id],
          z[:record_type].truncate(18),
          z[:record_id],
          z[:blob_id],
          z[:filename].truncate(23),
          z[:content_type].to_s.truncate(18),
          ActiveSupport::NumberHelper.number_to_human_size(z[:byte_size])
        ]
      end

      total_bytes = zombies.sum { |z| z[:byte_size] }
      puts "-" * 110
      puts "Total: #{zombies.size} zombies, #{ActiveSupport::NumberHelper.number_to_human_size(total_bytes)} at risk"
    end
  end

  desc "Storage usage by blog"
  task blogs: :environment do
    blogs = Blog.all.filter_map { |b|
      count = b.attachment_count
      next if count == 0
      [ b.subdomain, count, b.attachment_storage_bytes ]
    }.sort_by { |_, _, bytes| -bytes }

    if blogs.empty?
      puts "No blogs with attachments."
      next
    end

    puts "%-30s %7s  %s" % [ "Blog", "Files", "Storage" ]
    puts "-" * 55

    blogs.each do |subdomain, count, bytes|
      puts "%-30s %7d  %s" % [ subdomain, count, ActiveSupport::NumberHelper.number_to_human_size(bytes) ]
    end

    puts "-" * 55
    puts "%-30s %7d  %s" % [ "Total", blogs.sum { |_, c, _| c }, ActiveSupport::NumberHelper.number_to_human_size(blogs.sum { |_, _, b| b }) ]
  end
end
