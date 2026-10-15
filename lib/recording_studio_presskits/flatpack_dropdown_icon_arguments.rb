# frozen_string_literal: true

module RecordingStudioPresskits
  # Publishable 0.9 passes icon_variant and icon_style into the dropdown.
  # Flatpack 0.1.240 keeps unknown keywords and prints them on the wrapper.
  # Drop those two when this dropdown does not declare them. A later Flatpack
  # that declares them keeps the keywords and paints the icon.
  module FlatpackDropdownIconArguments
    def initialize(*, **kwargs, &)
      super(*, **without_undeclared_icon_arguments(kwargs), &)
    end

    private

    def without_undeclared_icon_arguments(kwargs)
      return kwargs if dropdown_declares?(:icon_style)

      kwargs.except(:icon_variant, :icon_style)
    end

    def dropdown_declares?(name)
      method = method(:initialize).super_method
      method = method.super_method while method && method.owner != FlatPack::Button::Dropdown::Component
      return false unless method

      method.parameters.any? { |_type, parameter| parameter == name }
    end
  end
end
