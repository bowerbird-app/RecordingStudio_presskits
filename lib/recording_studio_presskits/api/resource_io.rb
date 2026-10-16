# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module ResourceIo
      class Index
        def self.call(context)
          Gate.page(context, readable_relation(context))
        end

        def self.readable_relation(context)
          parent = Gate.nested_parent(context)
          authorize_index!(context, parent)
          ids = Gate.readable_ids(context, filtered(context, parent))
          context.scoped_recordings.where(RecordingStudio::Recording.arel_table[:id].in(ids))
        end

        def self.authorize_index!(context, parent)
          return Gate.ensure_readable!(context, parent) if parent

          scope = context.access_grant.scope_recording || context.root_recording
          context.access_grant.authorize!(recording: scope, role: :view)
        end

        def self.filtered(context, parent)
          relation = context.scoped_recordings.where(recordable_type: context.recordable_type)
          relation = relation.where(parent_recording_id: parent.id) if parent
          return relation unless context.recordable_type == PressKit.name

          Gate.search_title(relation, context)
        end
        private_class_method :readable_relation, :authorize_index!, :filtered
      end

      class Show
        def self.call(context)
          recording = Gate.find!(context)
          Gate.ensure_readable!(context, recording)
          { json: Gate.serialize(context, recording) }
        end
      end

      class Create
        def self.call(context)
          parent = Gate.parent!(context)
          Gate.authorize!(context, parent, :edit)
          { json: Gate.serialize(context, create_record(context, parent)), status: :created }
        rescue ActiveRecord::RecordInvalid => e
          SectionAction.reject!(e.record.errors.full_messages.to_sentence)
        end

        def self.create_record(context, parent)
          parent.record(context.recordable_type.constantize, **record_options(context, parent)) do |recordable|
            recordable.assign_attributes(Gate.writable(context))
          end
        end

        def self.record_options(context, parent)
          { parent_recording: parent, actor: Gate.actor(context) }
        end
        private_class_method :create_record, :record_options
      end

      class Update
        def self.call(context)
          recording = Gate.find!(context)
          Gate.authorize!(context, recording, :edit)
          { json: Gate.serialize(context, revise(context, recording)) }
        rescue ActiveRecord::RecordInvalid => e
          SectionAction.reject!(e.record.errors.full_messages.to_sentence)
        end

        def self.revise(context, recording)
          attributes = Gate.writable(context)
          return recording if attributes.empty?

          recording.root_recording.revise(recording, actor: Gate.actor(context)) do |recordable|
            recordable.assign_attributes(attributes)
          end
        end
        private_class_method :revise
      end

      class Destroy
        def self.call(context)
          recording = Gate.find!(context)
          Gate.authorize!(context, recording, :admin)
          recording.recording_studio_trashable_trash!(actor: Gate.actor(context))
          Gate.deleted(context, recording.reload)
        end
      end
    end

    class CreditCreate
      def self.call(context)
        created = create_credit(context)
        { json: Gate.serialize(context, created), status: :created }
      rescue ActiveRecord::RecordInvalid => e
        SectionAction.reject!(e.record.errors.full_messages.to_sentence)
      end

      def self.create_credit(context)
        parent = Gate.parent!(context)
        root = parent.root_recording
        Gate.authorize!(context, root, :edit)
        Credits.create!(root_recording: root, actor: Gate.actor(context), **credit_attributes(context))
      end

      def self.credit_attributes(context)
        {
          name: Gate.param(context, :name),
          url: Gate.param(context, :url),
          usual_role: Gate.param(context, :usual_role)
        }
      end
      private_class_method :create_credit, :credit_attributes
    end

    class CreditLineCreate
      def self.call(context)
        { json: Gate.serialize(context, create_line(context)), status: :created }
      end

      def self.create_line(context)
        parent = Gate.parent!(context)
        Gate.authorize!(context, parent, :edit)
        SectionAction.require_recording!(parent, CreditsSection, "expected a credits section")
        Credits.add!(**line_attributes(context, parent))
      end

      def self.line_attributes(context, parent)
        credit = Credits.find_for_root(parent.root_recording, Gate.param(context, :credit_id))
        SectionAction.reject!("That credit is not in this workspace") if credit.blank?

        {
          credits_section_recording: parent,
          credit_recording: credit,
          role: Gate.param(context, :role),
          icon: Gate.param(context, :icon),
          actor: Gate.actor(context)
        }
      end
      private_class_method :create_line, :line_attributes
    end
  end
end
