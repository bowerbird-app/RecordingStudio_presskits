# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    # Empty section containers have no columns of their own. Nested item
    # routes carry the records. This marks which content recording it is.
    class ContainerPayload
      def self.for(recordable, **)
        { kind: recordable.class.name.demodulize.underscore }
      end
    end
  end
end
