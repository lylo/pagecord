# The concern lives in app/controllers/concerns; this hook is here because the
# controller belongs to Active Storage, so there is no class of ours to include
# it from. The block runs when the controller loads, not at boot.
Rails.autoloaders.main.on_load("ActiveStorage::DirectUploadsController") do |klass, _abspath|
  klass.include DirectUploadValidation unless klass < DirectUploadValidation
end
