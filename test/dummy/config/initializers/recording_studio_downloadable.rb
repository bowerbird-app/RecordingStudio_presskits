# frozen_string_literal: true

RecordingStudioDownloadable.configure do |config|
  config.skip_host_before_actions = %i[authenticate_user! set_current_actor]
end
