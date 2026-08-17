# db:fixtures:load only clears tables that have a fixture file, and there are
# none for Active Storage. Blobs and attachments therefore survive every reseed
# and pile up, and a stale attachment row whose rich text has been wiped will
# reattach itself to whatever new record later takes its record_id, showing up
# as a phantom upload. Clear them so a reseed really does start from nothing.
#
# Rows only: the files under storage/ are left alone. They're unreferenced once
# the rows are gone, so `rm -rf storage/*` if you want the disk back too.
raise "Refusing to seed outside development or test" unless Rails.env.local?

ActiveStorage::Attachment.delete_all
ActiveStorage::VariantRecord.delete_all
ActiveStorage::Blob.delete_all

Rake.application["db:fixtures:load"].invoke
