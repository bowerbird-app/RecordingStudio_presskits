# frozen_string_literal: true

module RecordingStudioPresskits
  class Configuration
    attr_accessor :parent_root_type, :authentication_method, :current_actor_method, :section_components
    attr_reader :hooks

    def initialize
      @parent_root_type = "Workspace"
      @authentication_method = :authenticate_user!
      @current_actor_method = :current_user
      @section_components = {}
      @hooks = RecordingStudio::Hooks.new
    end

    def to_h
      {
        parent_root_type: parent_root_type,
        authentication_method: authentication_method,
        current_actor_method: current_actor_method,
        section_components: section_components.dup,
        hooks_registered: hooks.instance_variable_get(:@registry).transform_values(&:size)
      }
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |k, v|
        key = k.to_s
        setter = "#{key}="
        public_send(setter, v) if respond_to?(setter)
      end
    end
  end
end
