# frozen_string_literal: true

module RecordingStudioPresskits
  # A copied kit must not keep the source window. The embargo gem clears the
  # release time and turns early access off.
  class EmbargoCopy
    def self.call(recordable)
      copy = recordable.dup
      cleared = RecordingStudioEmbargo.attributes_for_duplicate(recordable)
      copy.enabled = cleared.fetch(:enabled)
      copy.lifts_at = cleared.fetch(:lifts_at)
      copy.early_access = cleared.fetch(:early_access)
      copy
    end
  end
end
