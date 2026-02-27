namespace :cloudflare do
  desc "Register all existing custom domains as Cloudflare Custom Hostnames"
  task migrate_domains: :environment do
    Blog.where.not(custom_domain: [ nil, "" ]).find_each do |blog|
      if blog.cloudflare_custom_hostname_id.present?
        puts "Skipping #{blog.custom_domain} (already registered)"
        next
      end

      print "Registering #{blog.custom_domain}... "
      CloudflareSaasApi.new(blog).add_domain(blog.custom_domain)
      puts "done (#{blog.cloudflare_custom_hostname_id})"
      sleep 0.5
    rescue => e
      puts "FAILED: #{e.message}"
    end
  end
end
