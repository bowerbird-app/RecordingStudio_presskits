# frozen_string_literal: true

require "recording_studio"
require "recording_studio_accessible"
require "recording_studio_orderable"
require "recording_studio_publishable"
require "recording_studio_trashable"
require "recording_studio_duplicatable"
require "recording_studio_admin"
require "flat_pack"
require "recording_studio_presskits/version"
require "recording_studio_presskits/engine"
require "recording_studio_presskits/configuration"
require "recording_studio_presskits/kit_query"
require "recording_studio_presskits/admin"
require "recording_studio_presskits/api"
require "recording_studio_presskits/quote_order"

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

    # Registered section types that can be recorded under a press kit.
    # Declaring the kit as a parent does not make a type a section.
    def picker_types
      parent_type = press_kit_type_name
      excluded = Array(configuration.excluded_picker_types).map(&:to_s)
      registered = RecordingStudio.configuration.recordable_types.filter_map do |type|
        RecordingStudio.recordable_type_name(type)
      end

      section_types.select do |type_name|
        next false if excluded.include?(type_name)
        next false unless registered.include?(type_name)

        RecordingStudio.declared_allowed_parent_types_for(type_name).include?(parent_type)
      end
    end

    def section_types
      Array(configuration.section_types).filter_map { |type| RecordingStudio.recordable_type_name(type) }.uniq
    end

    def section?(recording_or_type)
      section_types.include?(section_type_name(recording_or_type))
    end

    def register_section(type_name, component: nil, editor: nil)
      name = RecordingStudio.recordable_type_name(type_name).to_s
      configuration.section_types = (section_types + [name]).uniq
      register_section_component(name, component) if component.present?
      register_section_editor(name, editor) if editor.present?
      name
    end

    def register_section_component(type_name, component)
      configuration.section_components[type_name.to_s] = component
    end

    def section_component_for(recording_or_type)
      type_name = section_type_name(recording_or_type)
      registered = configuration.section_components[type_name]
      return registered if registered.is_a?(Class)
      return registered.constantize if registered.present?

      "#{type_name}::Component".safe_constantize
    end

    def register_section_editor(type_name, component)
      configuration.section_editors[type_name.to_s] = component
    end

    def section_editor_for(recording_or_type)
      registered = configuration.section_editors[section_type_name(recording_or_type)]
      return registered if registered.is_a?(Class)
      return registered.constantize if registered.present?

      nil
    end

    private

    def section_type_name(recording_or_type)
      if recording_or_type.respond_to?(:recordable_type)
        recording_or_type.recordable_type.to_s
      else
        recording_or_type.to_s
      end
    end
  end
end
