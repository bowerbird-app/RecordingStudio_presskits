# frozen_string_literal: true

module RecordingStudioPresskits
  class Configuration
    attr_accessor :parent_root_type, :authentication_method, :current_actor_method, :section_types,
                  :section_components, :section_editors, :section_prepares, :excluded_picker_types,
                  :cover_colors, :default_cover_color, :cover_text_colors, :cover_text_auto,
                  :section_library_keys, :sign_in_path, :registration_path, :site_name
    attr_reader :hooks

    def initialize
      assign_base_defaults
      assign_cover_defaults
      @hooks = RecordingStudio::Hooks.new
    end

    def library_key_for(type_name)
      keys = (section_library_keys || {}).to_h
      name = type_name.to_s
      short = name.demodulize
      matched = keys.find do |key, _|
        [name, short].include?(key.to_s) || key.to_s.demodulize == short
      end
      (matched&.last || :default).to_sym
    end

    def cover_palette
      Cover::Palette.new(colors: cover_colors, default_color: default_cover_color)
    end

    def any_cover_color?
      cover_palette.any?
    end

    def cover_text_palette
      Cover::Palette.new(
        colors: cover_text_colors,
        fallback_colors: Cover::Palette::DEFAULT_TEXT_COLORS
      )
    end

    def any_cover_text_color?
      cover_text_palette.any?
    end

    def cover_text_auto?
      ActiveModel::Type::Boolean.new.cast(@cover_text_auto)
    end

    def to_h
      identity_settings.merge(editor_settings).merge(cover_settings).merge(hooks_registered: hook_counts)
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

    def assign_base_defaults
      @parent_root_type = "Workspace"
      @authentication_method = :authenticate_user!
      @current_actor_method = :current_user
      @section_types = []
      @section_components = {}
      @section_editors = {}
      @section_prepares = {}
      @excluded_picker_types = []
      assign_visibility_defaults
    end

    def assign_visibility_defaults
      @sign_in_path = "/users/sign_in"
      @registration_path = nil
      @site_name = nil
    end

    def assign_cover_defaults
      @section_library_keys = {}
      @cover_colors = Cover::Palette::DEFAULT_COLORS.dup
      @default_cover_color = Cover::Palette::DEFAULT_COLOR
      @cover_text_colors = Cover::Palette::DEFAULT_TEXT_COLORS.dup
      @cover_text_auto = true
    end

    def identity_settings
      {
        parent_root_type: parent_root_type, authentication_method: authentication_method,
        current_actor_method: current_actor_method, sign_in_path: sign_in_path,
        registration_path: registration_path, site_name: site_name
      }
    end

    def editor_settings
      {
        section_types: Array(section_types).map(&:to_s),
        section_components: section_components.dup,
        section_editors: section_editors.dup,
        excluded_picker_types: Array(excluded_picker_types).map(&:to_s),
        section_library_keys: (section_library_keys || {}).to_h
      }
    end

    def cover_settings
      {
        cover_colors: any_cover_color? ? :any : cover_palette.colors,
        default_cover_color: cover_palette.default_color,
        cover_text_colors: any_cover_text_color? ? :any : cover_text_palette.colors,
        cover_text_auto: cover_text_auto?
      }
    end

    def hook_counts
      hooks.instance_variable_get(:@registry).transform_values(&:size)
    end
  end
end
