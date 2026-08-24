# frozen_string_literal: true

require "recording_studio"
require "recording_studio_accessible"
require "recording_studio_orderable"
require "recording_studio_trashable"
require "recording_studio_duplicatable"
require "recording_studio_presskits/version"
require "recording_studio_presskits/engine"
require "recording_studio_presskits/configuration"

module RecordingStudioPresskits
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end

    # Core 4.2 stores type names as the class name. There is no declaration alias,
    # so later section addons must use this exact string as a parent.
    def press_kit_type_name
      RecordingStudio.recordable_type_name(PressKit)
    end

    # Host-registered types whose allowed_parent_types include PressKit.
    # Later addons opt in solely via their declaration. This gem does not
    # keep a list of section types.
    def picker_types
      parent_type = press_kit_type_name

      RecordingStudio.configuration.recordable_types.filter_map do |type|
        type_name = RecordingStudio.recordable_type_name(type)
        next if type_name.blank?
        next unless RecordingStudio.allowed_parent_types_for(type_name).include?(parent_type)

        type_name
      end
    end
  end
end
