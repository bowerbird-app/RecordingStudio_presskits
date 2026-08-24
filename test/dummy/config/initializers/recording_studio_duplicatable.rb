# frozen_string_literal: true

RecordingStudioDuplicatable.configure do |config|
  # Authorization comes from RecordingStudioAccessible.authorized?.
  # Suffix defaults to " (Copy)"; PressKit also sets suffix on the type include.
end
