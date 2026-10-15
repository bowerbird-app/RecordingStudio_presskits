# frozen_string_literal: true

RecordingStudioDownloadable.configure do |config|
  config.skip_host_before_actions = %i[authenticate_user! set_current_actor]
  # The suite publishes many kits in one process. A cap of 5 leaves later
  # publishes rescuing ConcurrentBuildLimitError, so the zip never enqueues
  # and the download request returns 429.
  next unless Rails.env.test?

  config.max_concurrent_builds = 0
  config.rate_limits = {
    ip: { limit: 0, period: 1.minute },
    actor: { limit: 0, period: 1.minute },
    recording: { limit: 0, period: 1.minute }
  }
end
