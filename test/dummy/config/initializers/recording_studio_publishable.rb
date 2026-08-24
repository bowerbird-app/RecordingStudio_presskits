# frozen_string_literal: true

RecordingStudioPublishable.configure do |config|
  # Live kits take their layout from PressKit's `.to` `public_layout`
  # (`recording_studio/default_layout`). Leave this unset so Publishable's
  # own screens keep their engine default.
  config.current_actor_resolver = lambda do |controller:|
    Current.actor.presence || (controller.respond_to?(:current_user, true) ? controller.send(:current_user) : nil)
  end
end
