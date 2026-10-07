# frozen_string_literal: true

# FlatPack 0.1.202 does not ship Fieldset. Loaded only when that file is absent.
module FlatPack
  module Fieldset
    # Names a cluster of controls. The title is a legend inside a fieldset.
    class Component < FlatPack::BaseComponent
      # Tailwind CSS scanning requires these classes to be present as string literals.
      # "text-[var(--surface-content-color)]" "text-[var(--surface-muted-content-color)]" "text-[var(--color-error)]"
      # "fp-fieldset" "min-w-0" "border-0" "p-0" "opacity-50"
      # "float-left" "w-full" "px-0" "text-sm" "font-semibold" "leading-snug"
      # "clear-both" "mt-3" "space-y-[var(--stack-gap-md)]" "mt-1" "text-xs"

      def initialize(title:, description: nil, disabled: false, error: nil, **system_arguments)
        super(**system_arguments)
        @title = title
        @description = normalize_description!(description)
        @disabled = disabled
        @error = normalize_error!(error)
        @fieldset_id = resolve_fieldset_id

        validate_title!
      end

      def call
        content_tag(:fieldset, **fieldset_attributes) do
          safe_join([
            render_legend,
            render_description,
            render_fields,
            render_error
          ].compact)
        end
      end

      private

      def render_legend
        content_tag(:legend, @title, class: legend_classes)
      end

      def render_description
        render_help_text(@description, id: description_id)
      end

      def render_fields
        content_tag(:div, content, class: fields_classes)
      end

      def render_error
        return if @error.blank?

        content_tag(:p, @error, id: error_id, class: error_classes)
      end

      def fieldset_attributes
        merge_attributes(
          class: fieldset_classes,
          id: @fieldset_id,
          aria: fieldset_aria,
          disabled: (@disabled ? true : nil)
        )
      end

      def fieldset_aria
        describedby = describedby_tokens(
          aria_attributes[:describedby] || aria_attributes["describedby"],
          (description_id if @description),
          (error_id if @error)
        )

        extra = {}
        extra[:describedby] = describedby if describedby.present?
        extra[:invalid] = "true" if @error.present?
        extra
      end

      def fieldset_classes
        classes(
          "fp-fieldset",
          "min-w-0",
          "border-0",
          "p-0",
          (@disabled ? "opacity-50" : nil)
        )
      end

      def legend_classes
        "float-left w-full px-0 text-sm font-semibold leading-snug text-[var(--surface-content-color)]"
      end

      def fields_classes
        "clear-both mt-3 space-y-[var(--stack-gap-md)]"
      end

      def help_text_classes
        "clear-both mt-1 text-xs text-[var(--surface-muted-content-color)]"
      end

      def error_classes
        "clear-both mt-1 text-sm text-[var(--color-error)]"
      end

      def description_id
        "#{@fieldset_id}_description"
      end

      def error_id
        "#{@fieldset_id}_error"
      end

      def resolve_fieldset_id
        explicit = @system_arguments[:id].presence || @system_arguments["id"].presence
        explicit.to_s.presence || "fieldset_#{SecureRandom.hex(4)}"
      end

      def validate_title!
        validate_text_option!(@title, name: :title)
        return if @title.to_s.strip.present?

        raise ArgumentError, "title is required"
      end

      def normalize_description!(description)
        validate_text_option!(description, name: :description)
        description.presence
      end

      def normalize_error!(error)
        validate_text_option!(error, name: :error)
        error.presence
      end
    end
  end
end
