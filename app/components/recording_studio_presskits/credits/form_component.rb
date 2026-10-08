# frozen_string_literal: true

module RecordingStudioPresskits
  module Credits
    class FormComponent < ViewComponent::Base
      def initialize(credit:, url:, method:, heading:, trash_path: nil)
        super()
        @credit = credit
        @url = url
        @method = method
        @heading = heading
        @trash_path = trash_path
      end

      attr_reader :credit

      def button_text
        @method.to_sym == :post ? "Create" : "Save"
      end
    end
  end
end
