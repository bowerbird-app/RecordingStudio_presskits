class HomeController < ApplicationController
  def index
    @workspace_tree = build_workspace_tree
  end

  private

  def build_workspace_tree
    recordings = RecordingStudio::Recording.recording_studio_trashable_active
                                           .includes(:recordable)
                                           .reorder(:recording_studio_orderable_position, :created_at, :id)
                                           .to_a
    recordings_by_parent_id = recordings.group_by(&:parent_recording_id)
    roots = workspace_tree_roots(recordings_by_parent_id)

    roots.map { |recording| build_workspace_tree_node(recording, recordings_by_parent_id) }
  end

  def workspace_tree_roots(recordings_by_parent_id)
    current = current_root_recording
    return [ current ] if current.present?

    recordings_by_parent_id.fetch(nil, [])
  end

  def build_workspace_tree_node(recording, recordings_by_parent_id)
    {
      label: workspace_tree_label(recording),
      children: recordings_by_parent_id.fetch(recording.id, []).map do |child|
        build_workspace_tree_node(child, recordings_by_parent_id)
      end
    }
  end

  def workspace_tree_label(recording)
    type_label = recording.type_label
    name = recording.name

    return type_label if name.blank? || name == type_label

    "#{type_label}: #{name}"
  end
end
