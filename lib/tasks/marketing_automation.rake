namespace :marketing_automation do
  desc "Send a getting started email after one day"
  task getting_started: :environment do
    MarketingAutomation.send_getting_started_emails
  end
end
