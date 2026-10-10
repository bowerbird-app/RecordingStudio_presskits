# frozen_string_literal: true

unless RecordingStudioAccessible.registered_audience?(:"presskits.verified_journalist")
  RecordingStudioAccessible.register_audience(
    :"presskits.verified_journalist",
    label_key: "recording_studio_presskits.audiences.verified_journalist"
  ) do |actor:, recording:, context:|
    actor.present? && actor.respond_to?(:verified_journalist?) && actor.verified_journalist?
  end
end

RecordingStudioAccessible.configure do |config|
  config.access_actor_types = [ "User" ]
  config.action_audiences[:"presskits.kit_view_full"] = {
    allowed: %i[public signed_in granted presskits.verified_journalist],
    default: :public,
    granted_roles: %i[view edit admin],
    granted_override: false,
    manage_role: :edit
  }
end
