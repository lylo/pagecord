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

  desc "List unattached blobs (purge candidates)"
  task orphans: :environment do
    orphans = ActiveStorage::Blob.unattached.order(created_at: :desc)
    count = orphans.count

    if count == 0
      puts "No unattached blobs found."
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
    desc "Download unattached blobs to local directory (OUTPUT_DIR env var)"
    task download: :environment do
      output_dir = ENV.fetch("OUTPUT_DIR", Rails.root.join("tmp/orphaned_blobs").to_s)
      FileUtils.mkdir_p(output_dir)

      orphans = ActiveStorage::Blob.unattached.order(:id)
      count = orphans.count

      if count == 0
        puts "No unattached blobs to download."
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
end
