# Saving a rich text record attaches one ActiveStorage::Attachment per embedded
# blob, and each attachment runs the auto-generated presence validator on its
# `record` association (from `belongs_to_required_by_default`). When the record
# is an ActionText::RichText, EachValidator's `value.blank?` check delegates to
# `to_plain_text`, which re-renders the whole body and re-resolves every
# attachment's SGID – N blob queries per attachment, N² per save (~450 queries
# for a 20-photo post). Only `blank?`/`empty?`/`present?` trigger the render,
# so swap the validator for a nil check to keep saves linear.
#
# If a Rails upgrade changes how the validator registers, this silently no-ops;
# the query-budget test in test/models/post_test.rb is the tripwire.
ActiveSupport.on_load(:active_storage_attachment) do
  validator = _validators[:record].find { |v| v.is_a?(ActiveRecord::Validations::PresenceValidator) }

  if validator
    _validators[:record].delete(validator)
    skip_callback(:validate, validator)
    validate { errors.add(:record, :blank) if record.nil? }
  end
end
