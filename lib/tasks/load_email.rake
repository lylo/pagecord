namespace :email do
  desc "Loads an email from a file"
  task :load => :environment do |t, args|
    raw_email = File.read File.expand_path(ENV["FILE"])
    puts raw_email

    inbound_email = ActionMailbox::InboundEmail.create_and_extract_message_id! raw_email
    inbound_email.route
  end
end
