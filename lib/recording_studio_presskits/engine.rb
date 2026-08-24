# frozen_string_literal: true

module RecordingStudioPresskits
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioPresskits

    class << self
      def apply_model_extensions(target)
        apply_extensions(target, extensions_for(:model, extension_keys_for(target)))
      end

      def apply_controller_extensions(target)
        apply_extensions(target, extensions_for(:controller, extension_keys_for(target)))
      end

      private

      def extensions_for(kind, names)
        hooks = RecordingStudioPresskits.configuration.hooks
        Array(names).flat_map do |name|
          if kind == :model
            hooks.model_extensions_for(name)
          else
            hooks.controller_extensions_for(name)
          end
        end
      end

      def apply_extensions(target, extensions)
        return unless target

        applied = target.instance_variable_get(:@recording_studio_presskits_applied_extensions) || identity_hash

        extensions.flatten.compact.each do |extension|
          next if applied[extension]

          target.class_eval(&extension)
          applied[extension] = true
        end

        target.instance_variable_set(:@recording_studio_presskits_applied_extensions, applied)
      end

      def extension_keys_for(target)
        names = [target.name, target.name&.demodulize].compact.uniq
        names.map(&:to_sym)
      end

      def identity_hash
        {}.compare_by_identity
      end
    end

    initializer "recording_studio_presskits.before_initialize",
                before: "recording_studio_presskits.load_config" do |_app|
      RecordingStudioPresskits.configuration.hooks.run(:before_initialize, self)
    end

    initializer "recording_studio_presskits.load_config" do |app|
      if app.respond_to?(:config_for)
        begin
          yaml = begin
            app.config_for(:recording_studio_presskits)
          rescue StandardError
            nil
          end
          RecordingStudioPresskits.configuration.merge!(yaml) if yaml.respond_to?(:each)
        rescue StandardError => _e
          # ignore load errors; host app can provide initializer overrides
        end
      end

      if app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_presskits)
        xcfg = app.config.x.recording_studio_presskits
        if xcfg.respond_to?(:to_h)
          RecordingStudioPresskits.configuration.merge!(xcfg.to_h)
        else
          begin
            hash = {}
            xcfg.each_pair { |k, v| hash[k] = v } if xcfg.respond_to?(:each_pair)
            RecordingStudioPresskits.configuration.merge!(hash) if hash&.any?
          rescue StandardError => _e
            # ignore
          end
        end
      end

      RecordingStudioPresskits.configuration.hooks.run(:on_configuration, RecordingStudioPresskits.configuration)
    end

    initializer "recording_studio_presskits.after_initialize",
                after: "recording_studio_presskits.load_config" do |_app|
      RecordingStudioPresskits.configuration.hooks.run(:after_initialize, self)
    end

    initializer "recording_studio_presskits.apply_model_extensions" do
      config.to_prepare do
        next unless defined?(ActiveRecord::Base)

        ActiveRecord::Base.descendants.each do |model|
          next if model.abstract_class?

          RecordingStudioPresskits::Engine.apply_model_extensions(model)
        end
      end
    end

    initializer "recording_studio_presskits.apply_controller_extensions" do
      config.to_prepare do
        next unless defined?(ActionController::Base)

        ActionController::Base.descendants.each do |controller|
          RecordingStudioPresskits::Engine.apply_controller_extensions(controller)
        end
      end
    end

    initializer "recording_studio_presskits.helpers" do
      config.to_prepare do
        next unless defined?(Rails.application) && Rails.application.respond_to?(:helpers)

        RecordingStudioPresskits::ApplicationController.helper Rails.application.helpers
      rescue StandardError
        nil
      end
    end

    initializer "recording_studio_presskits.admin" do
      config.to_prepare do
        RecordingStudioPresskits::Admin.register!
      end
    end
  end
end
