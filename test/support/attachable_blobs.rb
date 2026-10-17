# frozen_string_literal: true

module AttachableBlobs
  def issued_attachment_blob!(recording, actor, io:, filename:, content_type:)
    ActiveStorage::Blob.create_and_upload!(
      io: io,
      filename: filename,
      content_type: content_type,
      metadata: RecordingStudioAttachable::DirectUpload.metadata_for(recording: recording, actor: actor)
    )
  end

  def declared_attachment_blob!(recording, actor, io:, filename:, content_type:)
    ActiveStorage::Blob.create_and_upload!(
      io: io,
      filename: filename,
      content_type: content_type,
      identify: false,
      metadata: RecordingStudioAttachable::DirectUpload.metadata_for(recording: recording, actor: actor)
    )
  end

  def attachment_signed_id(blob)
    RecordingStudioAttachable::DirectUpload.sign(blob)
  end
end
