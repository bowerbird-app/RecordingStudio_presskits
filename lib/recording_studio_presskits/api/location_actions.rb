# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module LocationActions
      class Set
        def self.call(context)
          SectionAction.authorize!(context)
          SectionAction.require_recording!(context.recording, LocationSection, "expected a location section")
          context.recording.record(
            RecordingStudio::Location::Location,
            parent_recording: context.recording,
            actor: context.access_grant.actor
          ) { |location| location.assign_attributes(attributes(context)) }
        rescue ActiveRecord::RecordInvalid => e
          SectionAction.reject!(e.record.errors.full_messages.to_sentence)
        end

        def self.attributes(context)
          context.params.slice(*RecordingStudio::Location.permitted_attributes)
        end
      end

      class Update
        def self.call(context)
          SectionAction.authorize!(context)
          SectionAction.require_recording!(context.recording, LocationSection, "expected a location section")
          place = find_place(context)
          context.recording.root_recording.revise(place, actor: context.access_grant.actor) do |location|
            location.assign_attributes(Set.attributes(context))
          end
        rescue ActiveRecord::RecordInvalid => e
          SectionAction.reject!(e.record.errors.full_messages.to_sentence)
        end

        def self.find_place(context)
          place = LocationSection.active_locations(context.recording).find_by(id: context.params[:location_id])
          SectionAction.reject!("That place is not in this section") if place.blank?

          place
        end
      end

      class Clear
        def self.call(context)
          SectionAction.authorize_admin!(context)
          SectionAction.require_recording!(context.recording, LocationSection, "expected a location section")
          place = Update.find_place(context)
          place.recording_studio_trashable_trash!(actor: context.access_grant.actor)
          place
        end
      end
    end
  end
end
