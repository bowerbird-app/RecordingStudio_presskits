# frozen_string_literal: true

module RecordingStudioPresskits
  class Configuration
    attr_accessor :parent_root_type, :authentication_method, :current_actor_method, :section_types,
                  :section_components, :section_editors, :section_prepares, :excluded_picker_types,
                  :sign_in_path, :registration_path, :site_name, :download_audience_icons
    attr_reader :hooks

    def initialize
      assign_base_defaults
      assign_host_defaults
      @hooks = RecordingStudio::Hooks.new
    end

    def to_h
      identity_settings.merge(editor_settings).merge(hooks_registered: hook_counts)
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
    end

    def assign_host_defaults
      @download_audience_icons = {}
      @sign_in_path = "/users/sign_in"
      @registration_path = nil
      @site_name = nil
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
        download_audience_icons: (download_audience_icons || {}).to_h
      }
    end

    def hook_counts
      hooks.instance_variable_get(:@registry).transform_values(&:size)
    end
  end
end
