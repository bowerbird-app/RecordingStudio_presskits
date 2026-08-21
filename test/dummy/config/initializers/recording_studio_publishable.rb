# frozen_string_literal: true

RecordingStudioPublishable.configure do |config|
  # Keep Publishable's own public chrome for live kits. Do not point this at
  # Recording Studio's default layout — that would replace the public shell.
  config.current_actor_resolver = lambda do |controller:|
    Current.actor.presence || (controller.respond_to?(:current_user, true) ? controller.send(:current_user) : nil)
  end
end
