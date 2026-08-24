# frozen_string_literal: true

require "recording_studio"
require "recording_studio_accessible"
require "recording_studio_orderable"
require "recording_studio_trashable"
require "recording_studio_duplicatable"
require "recording_studio_admin"
require "flat_pack"
require "recording_studio_presskits/version"
require "recording_studio_presskits/engine"
require "recording_studio_presskits/configuration"
require "recording_studio_presskits/kit_query"
require "recording_studio_presskits/admin"

module RecordingStudioPresskits
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
      configuration
    end

    def parent_root_type
      configuration.parent_root_type.presence || "Workspace"
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

    def register_section_component(type_name, component)
      configuration.section_components[type_name.to_s] = component
    end

    def section_component_for(recording_or_type)
      type_name = if recording_or_type.respond_to?(:recordable_type)
                    recording_or_type.recordable_type.to_s
                  else
                    recording_or_type.to_s
                  end

      registered = configuration.section_components[type_name]
      return registered if registered.is_a?(Class)
      return registered.constantize if registered.present?

      "#{type_name}::Component".safe_constantize
    end
  end
end
