# frozen_string_literal: true

module RecordingStudioPresskits
  # Press kits ask the embargo gem whether a named action is temporarily
  # restricted. Publishable still decides whether the kit is live. Accessible
  # still decides the standing audience. The fallback for a denial is the
  # kit's own preview or hidden setting.
  module Embargo
    VIEW = :"presskits.kit_view_full"
    DOWNLOAD = :"presskits.kit_download"
    ACTIONS = [VIEW, DOWNLOAD].freeze
    RESTRICTIONS = %i[allow deny not_applicable].freeze

    class << self
      def enabled?
        defined?(RecordingStudio::Capabilities::Embargo) &&
          defined?(RecordingStudioEmbargo)
      end

      def install!
        return unless enabled?
        return unless defined?(PressKit)
        return if capability_enabled?

        PressKit.include RecordingStudio::Capabilities::Embargo.to(actions: ACTIONS)
      end

      def denies?(recording:, action:, actor:)
        restriction_for(recording: recording, action: action, actor: actor) == :deny
      end

      def active?(recording)
        return false if recording.blank? || !enabled?
        return false unless recording.respond_to?(:embargo_active?)

        recording.embargo_active?
      rescue StandardError
        true
      end

      def lifts_at(recording)
        current(recording)&.lifts_at
      end

      def time_zone(recording)
        current(recording)&.time_zone
      end

      def restricted_presentation(recording)
        choice = KitSettings.fallback_for(recording)
        choice.to_s == "hidden" ? :hidden : :preview
      end

      def restriction_for(recording:, action:, actor:)
        return :not_applicable if recording.blank? || !enabled?

        name = RecordingStudioEmbargo.restriction_for(
          recording: recording, action: action, actor: actor
        ).to_s.to_sym
        return :deny unless RESTRICTIONS.include?(name)

        name
      rescue StandardError
        :deny
      end

      def withhold_protected?(recording:, actor:)
        kit = kit_recording(recording)
        return false if kit.blank?
        return false unless denies?(recording: kit, action: VIEW, actor: actor)

        !Visibility.edits?(actor, kit)
      end

      def kit_recording(recording)
        current = recording
        seen = {}.compare_by_identity
        while current && !seen[current]
          seen[current] = true
          return current if press_kit?(current)

          current = current.respond_to?(:parent_recording) ? current.parent_recording : nil
        end
        nil
      end

      private

      def capability_enabled?
        defined?(RecordingStudio) &&
          RecordingStudio.respond_to?(:capability_enabled?) &&
          RecordingStudio.capability_enabled?(:embargo, for: PressKit)
      end

      def current(recording)
        return unless recording.respond_to?(:current_embargo)

        recording.current_embargo
      end

      def press_kit?(recording)
        recording.respond_to?(:recordable_type) &&
          recording.recordable_type.to_s == RecordingStudioPresskits.press_kit_type_name
      end
    end
  end
end
