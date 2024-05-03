namespace :email do
  desc "Loads all .eml files from a directory into PostsMailbox"
  task load: :environment do
    ENV["PAGECORD_RECIPIENT"]="joel_gf35jsue@post.pagecord.com"
    ENV["PAGECORD_FROM"] ="joel@meyerowitz.xyz"
    ENV["PAGECORD_REPLYTO"] = ENV["PAGECORD_FROM"]

    dir_path = ENV["DIR"]

    unless dir_path.present? && Dir.exist?(dir_path)
      puts "Error: Please provide a valid directory path via the DIR environment variable."
      exit
    end

    # remove all inbound emails
    ActionMailbox::InboundEmail.destroy_all

    Dir.glob("#{dir_path}/*.eml").each do |file_path|
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