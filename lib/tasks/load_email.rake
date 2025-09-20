namespace :email do
  desc "Loads .eml files from a directory (DIR) or a single file (FILE) into PostsMailbox"
  task load: :environment do
    ActiveJob::Base.queue_adapter = :async

    ENV["PAGECORD_RECIPIENT"] ="joel_gf35jsue@post.pagecord.com"
    ENV["PAGECORD_FROM"] ="joel@pagecord.com"
    ENV["PAGECORD_REPLYTO"] = ENV["PAGECORD_FROM"]

    dir_path = ENV["DIR"]
    file_path = ENV["FILE"]

    # Validate input - must provide either DIR or FILE
    if dir_path.present? && file_path.present?
      puts "Error: Please provide either DIR or FILE environment variable, not both."
      exit
    end

    unless dir_path.present? || file_path.present?
      puts "Error: Please provide either a directory path via DIR or a file path via FILE environment variable."
      exit
    end

    # Validate directory exists if DIR is provided
    if dir_path.present? && !Dir.exist?(dir_path)
      puts "Error: Directory does not exist: #{dir_path}"
      exit
    end

    # Validate file exists if FILE is provided
    if file_path.present? && !File.exist?(file_path)
      puts "Error: File does not exist: #{file_path}"
      exit
    end

    # remove all inbound emails
    ActionMailbox::InboundEmail.destroy_all

    # Collect files to process
    files_to_process = if dir_path.present?
      Dir.glob("#{dir_path}/*.eml")
    else
      [ file_path ]
    end

    files_to_process.each do |file_path|
      begin
        puts "Processing email from file: #{file_path}"
        raw_email = File.read(file_path)
        ActionMailbox::InboundEmail.create_and_extract_message_id!(raw_email)
      rescue => e
        puts "Error processing email from file #{file_path}: #{e.message}"
      end
    end

    ActiveJob::Base.queue_adapter.shutdown
  end
end
