# Trusts the declared content type, which the storage service enforces on the
# upload, so attaching the blob doesn't fetch it back to sniff its type.
module DirectUploadIdentification
  private

    def blob_args
      super.merge(metadata: { identified: true })
    end
end
