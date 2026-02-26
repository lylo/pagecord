namespace :ses do
  desc "Provision SES, SNS, and SQS resources for email delivery"
  task provision: :environment do
    primary_region = ENV.fetch("AWS_SES_REGION", "eu-west-2")
    failover_region = "eu-west-1"
    domain = "send.pagecord.com"
    mail_from_subdomain = "bounce"
    credentials = Aws::Credentials.new(
      ENV.fetch("AWS_SES_ACCESS_KEY_ID"),
      ENV.fetch("AWS_SES_SECRET_ACCESS_KEY")
    )

    ses_primary = Aws::SESV2::Client.new(region: primary_region, credentials: credentials)
    ses_failover = Aws::SESV2::Client.new(region: failover_region, credentials: credentials)
    sns_primary = Aws::SNS::Client.new(region: primary_region, credentials: credentials)
    sns_failover = Aws::SNS::Client.new(region: failover_region, credentials: credentials)
    sqs_client = Aws::SQS::Client.new(region: primary_region, credentials: credentials)

    puts "=== Step 1: Verify domain identity in #{primary_region} ==="
    begin
      ses_primary.create_email_identity(email_identity: domain)
      puts "  Created email identity for #{domain}"
    rescue Aws::SESV2::Errors::AlreadyExistsException
      puts "  Email identity already exists for #{domain}"
    end

    puts "\n=== Step 2: Verify domain identity in #{failover_region} ==="
    begin
      ses_failover.create_email_identity(email_identity: domain)
      puts "  Created email identity for #{domain} in #{failover_region}"
    rescue Aws::SESV2::Errors::AlreadyExistsException
      puts "  Email identity already exists for #{domain} in #{failover_region}"
    end

    puts "\n=== Step 3: Configure MAIL FROM domain ==="
    [ ses_primary, ses_failover ].each_with_index do |ses, i|
      region = i == 0 ? primary_region : failover_region
      begin
        ses.put_email_identity_mail_from_attributes(
          email_identity: domain,
          mail_from_domain: "#{mail_from_subdomain}.#{domain}"
        )
        puts "  Configured MAIL FROM #{mail_from_subdomain}.#{domain} in #{region}"
      rescue => e
        puts "  Warning: Could not set MAIL FROM in #{region}: #{e.message}"
      end
    end

    puts "\n=== Step 4: Create SNS topic in #{primary_region} ==="
    primary_topic = sns_primary.create_topic(name: "pagecord-ses-notifications")
    primary_topic_arn = primary_topic.topic_arn
    puts "  Topic ARN: #{primary_topic_arn}"

    puts "\n=== Step 5: Configure SES event destination in #{primary_region} ==="
    begin
      ses_primary.create_configuration_set(configuration_set_name: "pagecord-newsletters")
      puts "  Created configuration set: pagecord-newsletters"
    rescue Aws::SESV2::Errors::AlreadyExistsException
      puts "  Configuration set already exists"
    end

    begin
      ses_primary.create_configuration_set_event_destination(
        configuration_set_name: "pagecord-newsletters",
        event_destination_name: "bounces-and-complaints",
        event_destination: {
          enabled: true,
          matching_event_types: %w[BOUNCE COMPLAINT],
          sns_destination: { topic_arn: primary_topic_arn }
        }
      )
      puts "  Created event destination for bounces and complaints"
    rescue Aws::SESV2::Errors::AlreadyExistsException
      puts "  Event destination already exists"
    end

    puts "\n=== Step 6: Create SQS queue with DLQ in #{primary_region} ==="
    dlq = sqs_client.create_queue(queue_name: "pagecord-ses-bounces-dlq")
    dlq_url = dlq.queue_url
    dlq_attrs = sqs_client.get_queue_attributes(queue_url: dlq_url, attribute_names: [ "QueueArn" ])
    dlq_arn = dlq_attrs.attributes["QueueArn"]
    puts "  DLQ URL: #{dlq_url}"

    redrive_policy = { deadLetterTargetArn: dlq_arn, maxReceiveCount: 5 }.to_json
    queue = sqs_client.create_queue(
      queue_name: "pagecord-ses-bounces",
      attributes: { "RedrivePolicy" => redrive_policy }
    )
    queue_url = queue.queue_url
    queue_attrs = sqs_client.get_queue_attributes(queue_url: queue_url, attribute_names: [ "QueueArn" ])
    queue_arn = queue_attrs.attributes["QueueArn"]
    puts "  Queue URL: #{queue_url}"

    # Allow SNS to send messages to SQS
    policy = {
      Version: "2012-10-17",
      Statement: [ {
        Effect: "Allow",
        Principal: { Service: "sns.amazonaws.com" },
        Action: "sqs:SendMessage",
        Resource: queue_arn,
        Condition: { ArnLike: { "aws:SourceArn" => "arn:aws:sns:*:*:pagecord-ses-notifications" } }
      } ]
    }.to_json
    sqs_client.set_queue_attributes(queue_url: queue_url, attributes: { "Policy" => policy })
    puts "  Set SQS policy to allow SNS"

    puts "\n=== Step 7: Subscribe SQS queue to primary SNS topic ==="
    sns_primary.subscribe(
      topic_arn: primary_topic_arn,
      protocol: "sqs",
      endpoint: queue_arn
    )
    puts "  Subscribed SQS to primary SNS topic"

    puts "\n=== Step 8: Create SNS topic in #{failover_region} ==="
    failover_topic = sns_failover.create_topic(name: "pagecord-ses-notifications")
    failover_topic_arn = failover_topic.topic_arn
    puts "  Topic ARN: #{failover_topic_arn}"

    puts "\n=== Step 9: Configure SES event destination in #{failover_region} ==="
    begin
      ses_failover.create_configuration_set(configuration_set_name: "pagecord-newsletters")
      puts "  Created configuration set in #{failover_region}"
    rescue Aws::SESV2::Errors::AlreadyExistsException
      puts "  Configuration set already exists in #{failover_region}"
    end

    begin
      ses_failover.create_configuration_set_event_destination(
        configuration_set_name: "pagecord-newsletters",
        event_destination_name: "bounces-and-complaints",
        event_destination: {
          enabled: true,
          matching_event_types: %w[BOUNCE COMPLAINT],
          sns_destination: { topic_arn: failover_topic_arn }
        }
      )
      puts "  Created event destination in #{failover_region}"
    rescue Aws::SESV2::Errors::AlreadyExistsException
      puts "  Event destination already exists in #{failover_region}"
    end

    puts "\n=== Step 10: Subscribe primary SQS to failover SNS topic (cross-region) ==="
    sns_failover.subscribe(
      topic_arn: failover_topic_arn,
      protocol: "sqs",
      endpoint: queue_arn
    )
    puts "  Subscribed primary SQS to failover SNS topic"

    # Get DKIM tokens
    puts "\n=== DNS Records Required ==="
    identity = ses_primary.get_email_identity(email_identity: domain)
    dkim_tokens = identity.dkim_attributes.tokens

    puts "\nDKIM (3 CNAME records):"
    dkim_tokens.each do |token|
      puts "  #{token}._domainkey.#{domain} CNAME #{token}.dkim.amazonses.com"
    end

    puts "\nSPF:"
    puts "  #{domain} TXT \"v=spf1 include:amazonses.com ~all\""

    puts "\nDMARC:"
    puts "  _dmarc.#{domain} TXT \"v=DMARC1; p=none; rua=mailto:dmarc-reports@pagecord.com\""

    puts "\nCustom MAIL FROM:"
    puts "  #{mail_from_subdomain}.#{domain} MX 10 feedback-smtp.#{primary_region}.amazonses.com"
    puts "  #{mail_from_subdomain}.#{domain} TXT \"v=spf1 include:amazonses.com ~all\""

    puts "\n=== Environment Variables ==="
    puts "AWS_SES_ACCESS_KEY_ID=<already set>"
    puts "AWS_SES_SECRET_ACCESS_KEY=<already set>"
    puts "AWS_SES_REGION=#{primary_region}"
    puts "AWS_SES_BOUNCE_QUEUE_URL=#{queue_url}"
    puts "SES_MAX_SENDS_PER_SECOND=14"

    puts "\nDone! Add the DNS records above and set the environment variables."
  end

  desc "Check SES domain verification and sending status"
  task status: :environment do
    region = ENV.fetch("AWS_SES_REGION", "eu-west-2")
    domain = "send.pagecord.com"
    credentials = Aws::Credentials.new(
      ENV.fetch("AWS_SES_ACCESS_KEY_ID"),
      ENV.fetch("AWS_SES_SECRET_ACCESS_KEY")
    )

    ses = Aws::SESV2::Client.new(region: region, credentials: credentials)

    puts "=== SES Status for #{domain} (#{region}) ==="

    begin
      identity = ses.get_email_identity(email_identity: domain)
      puts "  Verified: #{identity.verified_for_sending_status}"
      puts "  DKIM status: #{identity.dkim_attributes.status}"
      puts "  DKIM signing: #{identity.dkim_attributes.signing_enabled}"

      if identity.mail_from_attributes
        puts "  MAIL FROM domain: #{identity.mail_from_attributes.mail_from_domain}"
        puts "  MAIL FROM status: #{identity.mail_from_attributes.mail_from_domain_status}"
      end
    rescue Aws::SESV2::Errors::NotFoundException
      puts "  Domain identity not found. Run `rake ses:provision` first."
      next
    end

    puts "\n=== Account Sending Status ==="
    account = ses.get_account
    puts "  Production access: #{!account.production_access_enabled.nil? && account.production_access_enabled}"
    puts "  Sending enabled: #{account.send_quota.nil? ? 'unknown' : 'yes'}"

    if account.send_quota
      puts "  Max send rate: #{account.send_quota.max_send_rate}/sec"
      puts "  Max 24hr send: #{account.send_quota.max_24_hour_send}"
      puts "  Sent last 24hr: #{account.send_quota.sent_last_24_hours}"
    end

    puts "\n=== Suppression Stats ==="
    puts "  Total suppressions: #{Email::Suppression.count}"
    puts "  Bounces: #{Email::Suppression.bounces.count}"
    puts "  Complaints: #{Email::Suppression.complaints.count}"
  end
end
