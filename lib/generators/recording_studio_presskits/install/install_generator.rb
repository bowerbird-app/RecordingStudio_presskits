# frozen_string_literal: true

require "rails/generators"

module RecordingStudioPresskits
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Installs RecordingStudioPresskits engine into your application"

      class_option(
        :mount_path,
        type: :string,
        default: "/recording_studio_presskits",
        desc: "Route prefix used when mounting the user slice"
      )

      class_option(
        :parent_root_type,
        type: :string,
        default: "Workspace",
        desc: "Host root recordable class name PressKit may nest under"
      )

      def mount_engine
        route %(mount RecordingStudioPresskits::Engine, at: "#{options[:mount_path]}")
      end

      def copy_initializer
        template "recording_studio_presskits_initializer.rb", "config/initializers/recording_studio_presskits.rb"
      end

      def add_yaml_config
        prompt = "Would you like to add `config/recording_studio_presskits.yml` " \
                 "for environment-specific settings? [y/N]"
        return unless yes?(prompt)

        template "recording_studio_presskits.yml", "config/recording_studio_presskits.yml"
      end

      def enable_admin_section
        admin_root_path = File.join(destination_root, "app/models/admin_root.rb")
        unless File.exist?(admin_root_path)
          say "No AdminRoot model found. After you install Recording Studio Admin, enable " \
              "`section :press_kits` on your admin root.", :yellow
          return
        end

        content = File.read(admin_root_path)
        if content.include?("section :press_kits")
          say "Admin root already enables the press kits section.", :green
          return
        end

        if content.include?("recording_studio_admin_sections do")
          inject_into_file admin_root_path, after: "recording_studio_admin_sections do\n" do
            "    section :press_kits\n"
          end
          say "Enabled the press kits Admin section on AdminRoot.", :green
        else
          say "Add `section :press_kits` inside recording_studio_admin_sections on your admin root.", :yellow
        end
      end

      def add_tailwind_source
        tailwind_css_path = Rails.root.join("app/assets/tailwind/application.css")
        return show_missing_tailwind_notice unless File.exist?(tailwind_css_path)

        tailwind_content = File.read(tailwind_css_path)
        missing_lines = missing_tailwind_source_lines(tailwind_content)

        if missing_lines.empty?
          say "Tailwind already configured to include RecordingStudioPresskits and FlatPack sources.", :green
          return
        end

        if tailwind_content.include?('@import "tailwindcss"')
          inject_tailwind_sources(tailwind_css_path, missing_lines)
          return
        end

        show_manual_tailwind_notice(missing_lines)
      end

      def show_readme
        readme "INSTALL.md" if behavior == :invoke
      end

      private

      def parent_root_type
        options[:parent_root_type].presence || "Workspace"
      end

      def show_missing_tailwind_notice
        say "Tailwind CSS not detected. Skipping Tailwind configuration.", :yellow
        say "If you use Tailwind, add these lines to your Tailwind CSS config:", :yellow
        tailwind_source_lines.each do |line|
          say "  #{line}", :yellow
        end
      end

      def missing_tailwind_source_lines(tailwind_content)
        tailwind_source_lines.reject { |line| tailwind_content.include?(line) }
      end

      def inject_tailwind_sources(tailwind_css_path, missing_lines)
        inject_into_file tailwind_css_path, after: "@import \"tailwindcss\";\n" do
          "#{formatted_tailwind_source_block(missing_lines)}\n"
        end
        say "Added RecordingStudioPresskits and FlatPack sources to Tailwind CSS configuration.", :green
        say "Run 'bin/rails tailwindcss:build' to rebuild your CSS.", :green
      end

      def formatted_tailwind_source_block(missing_lines)
        [
          "\n/* Include RecordingStudioPresskits engine views and components for Tailwind CSS */",
          missing_lines
        ].flatten.reject(&:empty?).join("\n")
      end

      def show_manual_tailwind_notice(missing_lines)
        say "Could not find @import \"tailwindcss\" in your Tailwind config.", :yellow
        say "Please manually add these lines to your Tailwind CSS config:", :yellow
        missing_lines.each do |line|
          say "  #{line}", :yellow
        end
      end

      def tailwind_source_lines
        [
          '@source "../../vendor/bundle/**/recording_studio_presskits/app/views/**/*.erb";',
          '@source "../../vendor/bundle/**/recording_studio_presskits/app/components/**/*.{rb,erb}";',
          '@source "../../../../../../usr/local/bundle/ruby/**/bundler/gems/' \
          'recording_studio_presskits-*/app/views/**/*.erb";',
          '@source "../../../../../../usr/local/bundle/ruby/**/bundler/gems/' \
          'recording_studio_presskits-*/app/components/**/*.{rb,erb}";',
          '@source "../../vendor/bundle/**/flatpack/app/components/**/*.{rb,erb}";',
          '@source "../../../../../../usr/local/bundle/ruby/**/bundler/gems/flatpack-*/app/components/**/*.{rb,erb}";'
        ]
      end
    end
  end
end
