# frozen_string_literal: true

module PresskitsApiMirror
  def with_recording_studio_api(registry)
    if real_recording_studio_api?
      yield
      mirror_presskits_api(registry)
      return
    end

    Object.const_set(:RecordingStudioApi, registry)
    yield
  ensure
    remove_fake_recording_studio_api
  end

  def real_recording_studio_api?
    defined?(::RecordingStudioApi) && ::RecordingStudioApi.respond_to?(:recordable_registration_for)
  end

  def remove_fake_recording_studio_api
    return if real_recording_studio_api?
    return unless defined?(::RecordingStudioApi)

    Object.send(:remove_const, :RecordingStudioApi)
  end

  def mirror_presskits_api(registry)
    RecordingStudioApi.configuration.recordable_registry.to_h.each do |type_name, registration|
      registry.types[type_name] = mirrored_registration(registration)
    end
  end

  def mirrored_registration(registration)
    mirrored = {
      operations: registration[:operations],
      capability_actions: symbols(registration[:capability_actions])
    }
    copy_list(mirrored, :output_keys, registration)
    copy_list(mirrored, :writable_attributes, registration)
    mirrored[:serializer] = registration[:serializer] if registration[:serializer]
    relationships = mirrored_relationships(registration)
    mirrored[:relationships] = relationships if relationships.any?
    mirrored
  end

  def copy_list(mirrored, key, registration)
    values = symbols(registration[key])
    mirrored[key] = values if values.any?
  end

  def mirrored_relationships(registration)
    Array(registration[:relationships]).to_h do |name, relationship|
      [name.to_sym, mirrored_relationship(relationship)]
    end
  end

  def mirrored_relationship(relationship)
    {
      endpoints: relationship[:endpoints],
      output_keys: symbols(relationship[:output_keys])
    }
  end

  def symbols(values)
    Array(values).map(&:to_sym)
  end
end
