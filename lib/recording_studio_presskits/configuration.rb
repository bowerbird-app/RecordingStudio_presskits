# frozen_string_literal: true

module RecordingStudioPresskits
  class Configuration
    attr_accessor :parent_root_type, :authentication_method, :current_actor_method, :section_types,
                  :section_components, :section_editors, :section_prepares, :excluded_picker_types,
                  :cover_colors, :default_cover_color
    attr_reader :hooks

    def initialize
      @parent_root_type = "Workspace"
      @authentication_method = :authenticate_user!
      @current_actor_method = :current_user
      @section_types = []
      @section_components = {}
      @section_editors = {}
      @section_prepares = {}
      @excluded_picker_types = []
      assign_cover_defaults
      @hooks = RecordingStudio::Hooks.new
    end

    def cover_palette
      Cover::Palette.new(colors: cover_colors, default_color: default_cover_color)
    end

    def any_cover_color?
      cover_palette.any?
    end

    def to_h
      base_settings.merge(cover_settings).merge(hooks_registered: hook_counts)
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |k, v|
        key = k.to_s
        setter = "#{key}="
        public_send(setter, v) if respond_to?(setter)
      end
    end

    private

    def assign_cover_defaults
      @cover_colors = Cover::Palette::DEFAULT_COLORS.dup
      @default_cover_color = Cover::Palette::DEFAULT_COLOR
    end

    def base_settings
      {
        parent_root_type: parent_root_type,
        authentication_method: authentication_method,
        current_actor_method: current_actor_method,
        section_types: Array(section_types).map(&:to_s),
        section_components: section_components.dup,
        section_editors: section_editors.dup,
        excluded_picker_types: Array(excluded_picker_types).map(&:to_s)
      }
    end

    def cover_settings
      {
        cover_colors: any_cover_color? ? :any : cover_palette.colors,
        default_cover_color: cover_palette.default_color
      }
    end

    def hook_counts
      hooks.instance_variable_get(:@registry).transform_values(&:size)
    end
  end
end
