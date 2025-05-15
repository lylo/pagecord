# lib/tasks/post_digests.rake
namespace :post_digests do
  desc "Deliver post digests to relevant subscribers at 8am in their local timezone"
  task deliver: :environment do
    PostDigestScheduler.run
  end
end
