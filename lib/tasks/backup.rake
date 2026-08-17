namespace :db do
  desc "Back up the database to Cloudflare R2 (independent off-Ubicloud hedge)"
  task backup: :environment do
    # :environment boots Rails so the app env (DATABASE_URL, CLOUDFLARE_R2_*) is
    # loaded, then bin/backup-db inherits it via the subprocess environment.
    abort("db:backup failed") unless system("bash", Rails.root.join("bin/backup-db").to_s)
  end
end
