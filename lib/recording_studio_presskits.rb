# frozen_string_literal: true

require "recording_studio"
require "recording_studio_accessible"
require "recording_studio_orderable"
require "recording_studio_publishable"
require "recording_studio_trashable"
require "recording_studio_duplicatable"
require "recording_studio_video"
require "recording_studio_admin"
require "recording_studio_company"
require "recording_studio_location"
require "flat_pack"
require "recording_studio_presskits/version"
require "recording_studio_presskits/engine"
require "recording_studio_presskits/cover/hex"
require "recording_studio_presskits/cover/contrast"
require "recording_studio_presskits/cover/palette"
require "recording_studio_presskits/cover_settings"
require "recording_studio_presskits/library_images"
require "recording_studio_presskits/cover_image"
require "recording_studio_presskits/section_images"
require "recording_studio_presskits/cover/company"
require "recording_studio_presskits/cover/byline"
require "recording_studio_presskits/cover/image"
require "recording_studio_presskits/kit_location"
require "recording_studio_presskits/header_attributes"
require "recording_studio_presskits/configuration"
require "recording_studio_presskits/kit_settings"
require "recording_studio_presskits/visibility"
require "recording_studio_presskits/kit_download"
require "recording_studio_presskits/kit_query"
require "recording_studio_presskits/section_composer"
require "recording_studio_presskits/legacy_section_tree"
require "recording_studio_presskits/api/press_kit_payload"
require "recording_studio_presskits/api/section_payload"
require "recording_studio_presskits/admin"
require "recording_studio_presskits/api"
require "recording_studio_presskits/metrics"
require "recording_studio_presskits/quote_order"
require "recording_studio_presskits/credits"
require "recording_studio_presskits/credits/picker"
require "recording_studio_presskits/credit_line_batch"
require "recording_studio_presskits/credit_line_batch/sync"

module RecordingStudioPresskits
  class << self
    include CoverSettings

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

    def press_kit_type_name
      RecordingStudio.recordable_type_name(PressKit)
    end

    def picker_types
      parent_type = KitSection.name
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
      section_type_name(recording_or_type) == KitSection.name
    end

    def create_section!(press_kit_recording:, content_type:, actor: nil, title: nil, subtitle: nil)
      SectionComposer.create!(
        press_kit_recording: press_kit_recording,
        content_type: content_type,
        actor: actor,
        title: title,
        subtitle: subtitle
      )
    end

    def section_heading(section_recording)
      section_recording.recordable.title.to_s.strip.presence || default_section_heading(section_recording)
    end

    def default_section_heading(section_recording)
      KitQuery.section_content(section_recording)&.type_label.presence || section_recording.type_label
    end

    def register_section(type_name, component: nil, editor: nil, prepare: nil)
      name = RecordingStudio.recordable_type_name(type_name).to_s
      configuration.section_types = (section_types + [name]).uniq
      register_section_component(name, component) if component.present?
      register_section_editor(name, editor) if editor.present?
      configuration.section_prepares[name] = prepare if prepare
      name
    end

    def prepare_section_content(type_name, recordable, title: nil)
      handler = configuration.section_prepares[section_type_name(type_name)]
      return unless handler

      handler.call(recordable, title: title)
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
