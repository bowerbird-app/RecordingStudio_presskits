# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

find_or_record_child = lambda do |recordable, root_recording, parent_recording|
  RecordingStudio::Recording.recording_studio_trashable_active.find_by(
    root_recording: root_recording,
    parent_recording: parent_recording,
    recordable: recordable
  ) || RecordingStudio.record!(
    action: "created",
    recordable: recordable,
    root_recording: root_recording,
    parent_recording: parent_recording
  ).recording
end

find_or_record_named_child = lambda do |type, title, root_recording, parent_recording, description: nil, subtitle: nil, brand_color: nil, font_family: nil|
  existing = RecordingStudio::Recording.recording_studio_trashable_active
                                       .where(root_recording: root_recording, parent_recording: parent_recording,
                                              recordable_type: type.name)
                                       .find { |recording| recording.recordable.title == title }
  return existing if existing

  parent_recording.record(type, parent_recording: parent_recording) do |recordable|
    recordable.title = title
    recordable.description = description if description.present?
    recordable.subtitle = subtitle if subtitle.present? && recordable.respond_to?(:subtitle=)
    recordable.brand_color = brand_color if brand_color.present? && recordable.respond_to?(:brand_color=)
    recordable.font_family = font_family if font_family.present? && recordable.respond_to?(:font_family=)
  end
end

bootstrap_owner_access = lambda do |recording, actor|
  current_role = RecordingStudioAccessible.role_for(actor: actor, recording: recording)
  next if current_role == :admin

  result = RecordingStudioAccessible.bootstrap_owner_access!(
    recording: recording,
    actor: actor
  )

  raise result.error if result.failure?
end

# Create the admin user
user = User.find_or_create_by!(email: "admin@admin.com") do |u|
  u.password = "Password"
  u.password_confirmation = "Password"
end

# Create the workspace recordables
workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
accessible_workspace = Workspace.find_or_create_by!(name: "Client Workspace")
private_workspace = Workspace.find_or_create_by!(name: "Private Workspace")
folder = Folder.find_or_create_by!(name: "Product Docs")
page = Page.find_or_create_by!(title: "Getting Started")
admin_root = AdminRoot.find_or_create_by!(name: "Admin")

previous_actor = Current.actor
Current.actor = user

begin
  root_recording = RecordingStudio.root_recording_for(workspace)
  accessible_root_recording = RecordingStudio.root_recording_for(accessible_workspace)
  private_root_recording = RecordingStudio.root_recording_for(private_workspace)
  admin_root_recording = RecordingStudio.root_recording_for(admin_root)

  folder_recording = find_or_record_child.call(folder, root_recording, root_recording)

  find_or_record_child.call(page, root_recording, folder_recording)

  press_kit_recording = find_or_record_named_child.call(
    RecordingStudioPresskits::PressKit,
    "Spring launch",
    root_recording,
    root_recording,
    description: "Doors at noon. The one-sheet is inside, with the photos, the credits, and the stats.",
    subtitle: "Collection released"
  )
  [root_recording, accessible_root_recording, private_root_recording, admin_root_recording].each do |recording|
    bootstrap_owner_access.call(recording, user)
  end
  if RecordingStudioCompany.company(root_recording).blank?
    RecordingStudioCompany.create(
      root_recording,
      actor: user,
      idempotency_key: "seed:harbour-studio",
      name: "Harbour Studio"
    )
  end
  unless RecordingStudio::Recording.recording_studio_trashable_active.exists?(
    parent_recording: press_kit_recording,
    recordable_type: "RecordingStudio::Location::Location"
  )
    press_kit_recording.record(RecordingStudio::Location::Location, actor: user, parent_recording: press_kit_recording) do |location|
      location.title = "Harbour Gallery"
      location.location_type = "venue"
      location.locality = "Sydney"
      location.country_code = "AU"
    end
  end
  attach_harbour_photo = lambda do |parent, source:|
    next if parent.blank? || !parent.respond_to?(:import_attachment)

    existing = RecordingStudioPresskits::DirectImages.list(parent).find do |recording|
      recording.recordable.original_filename == "harbour-gallery.jpg"
    end
    next existing if existing

    path = Rails.root.join("db/seed_images/harbour-gallery.jpg")
    next unless path.file?

    photo = File.open(path, "rb") do |io|
      parent.import_attachment(
        io: io,
        filename: "harbour-gallery.jpg",
        content_type: "image/jpeg",
        name: "Harbour Gallery",
        actor: user,
        source: source
      )
    end
    next if photo.blank?

    photo.revise_attachment_metadata(
      actor: user,
      alt_text: "A white gallery hall with paintings along both walls"
    )
    if parent.recordable.is_a?(RecordingStudioPresskits::Images)
      parent.recording_studio_orderable_append!(photo, actor: user)
    end
    photo
  end
  attach_harbour_photo.call(press_kit_recording, source: "press_kit_cover")
  spring_cover = press_kit_recording.recordable
  spring_description = "Doors at noon. The one-sheet is inside, with the photos, the credits, and the stats."
  if spring_cover.subtitle != "Collection released" || spring_cover.description != spring_description
    root_recording.revise(press_kit_recording) do |press_kit|
      press_kit.subtitle = "Collection released"
      press_kit.description = spring_description
    end
    press_kit_recording.reload
  end

  unpublished_kit_recording = RecordingStudio::Recording.recording_studio_trashable_active
                                                        .where(root_recording: root_recording,
                                                               parent_recording: root_recording,
                                                               recordable_type: "RecordingStudioPresskits::PressKit")
                                                        .find { |recording| recording.recordable.title == "Autumn recap" }
  if unpublished_kit_recording.nil?
    unpublished_kit_recording = root_recording.record(RecordingStudioPresskits::PressKit) do |press_kit|
      press_kit.title = "Autumn recap"
      press_kit.description = "What we shipped, on one page."
    end
  end

  trash_named_child = lambda do |parent_recording, type, title|
    existing = RecordingStudio::Recording.recording_studio_trashable_active
                                         .where(root_recording: root_recording,
                                                parent_recording: parent_recording,
                                                recordable_type: type.name)
                                         .find { |recording| recording.recordable.title == title }
    return unless existing&.respond_to?(:recording_studio_trashable_trash!)

    existing.recording_studio_trashable_trash!(actor: user)
  end

  %w[Hero Quotes].each do |title|
    trash_named_child.call(press_kit_recording, RecordingStudioPresskits::KitSection, title)
  end
  trash_named_child.call(unpublished_kit_recording, RecordingStudioPresskits::KitSection, "Notes")

  publish_kit = lambda do |kit_recording, slug:, status:|
    result = RecordingStudioPublishable::Services::Publishables::Update.call(
      parent_recording: kit_recording,
      actor: user,
      attributes: {
        slug: slug,
        status: status,
        meta_robots: "index,follow"
      }
    )
    raise result.error if result.failure?

    result.value
  end

  publish_kit.call(press_kit_recording, slug: "spring-launch", status: "published")
  publish_kit.call(unpublished_kit_recording, slug: "autumn-recap", status: "draft")

  find_or_record_credit = lambda do |root_recording, name, usual_role, url|
    existing = RecordingStudioPresskits::Credits.active_for_root(root_recording).find do |recording|
      recording.recordable.name == name
    end
    return existing if existing

    RecordingStudioPresskits::Credits.create!(
      root_recording: root_recording,
      name: name,
      url: url,
      usual_role: usual_role,
      actor: user
    )
  end

  ensure_credits_section = lambda do |kit_recording, title, lines|
    existing = RecordingStudioPresskits::KitQuery.sections_for(kit_recording).find do |section|
      section.recordable.title == title
    end
    section = existing || RecordingStudioPresskits.create_section!(
      press_kit_recording: kit_recording,
      content_type: "RecordingStudioPresskits::CreditsSection",
      actor: user,
      title: title
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    lines.each do |credit_recording, role|
      already = RecordingStudioPresskits::Credits.lines_for(content).any? do |line|
        line.recordable.credit_recording_id == credit_recording.id && line.recordable.role == role
      end
      next if already

      RecordingStudioPresskits::Credits.add!(
        credits_section_recording: content,
        credit_recording: credit_recording,
        role: role,
        actor: user
      )
    end
  end

  studio_bright = find_or_record_credit.call(root_recording, "Studio Bright", "Architecture", "https://studiobright.com.au")
  flack = find_or_record_credit.call(root_recording, "Flack Studio", "Interior Design", "https://flackstudio.com.au")
  tom = find_or_record_credit.call(root_recording, "Tom Ross", "Photography", nil)
  marsha = find_or_record_credit.call(root_recording, "Marsha Golemac", "Styling", nil)
  vitra = find_or_record_credit.call(root_recording, "Vitra", "Furniture", "https://www.vitra.com")

  ensure_credits_section.call(
    press_kit_recording,
    "Project credits",
    [
      [studio_bright, "Architecture"],
      [flack, "Interior Design"],
      [tom, "Photography"],
      [marsha, "Styling"],
      [vitra, "Furniture"]
    ]
  )
  ensure_credits_section.call(unpublished_kit_recording, "Credits", [[tom, "Creative Direction"]])

  press_image_seeds = [
    ["hero-pendant.jpg", "Hero — Pendant", "Oat ceramic pendant against plaster."],
    ["detail-glow.jpg", "Detail — Glow", "Warm light under the shade."],
    ["detail-brass.jpg", "Detail — Brass cap", "Brass cap where the cord meets the shade."],
    ["full-drop.jpg", "Pendant — Full drop", "The full drop of the pendant."],
    ["studio-wide.jpg", "Studio — Wide", "The pendant in a quiet studio."],
    ["lifestyle-wall.jpg", "Lifestyle — Wall", "Morning light beside the wall."],
    ["detail-shade.jpg", "Detail — Shade", "The ceramic surface of the shade."],
    ["light-study.jpg", "Light study — Wall", "A pool of light on plaster."],
    ["detail-cord.jpg", "Detail — Cord", "Black cord and brass cap."],
    ["lifestyle-table.jpg", "Lifestyle — Table", "The pendant over a pale oak table."],
    ["studio-room.jpg", "Studio — Room", "The lamp lit in the evening room."],
    ["overhead-shade.jpg", "Overhead — Shade", "Looking down on the shade."],
    ["evening-insitu.jpg", "Evening — In situ", "The pendant lit after dusk."],
    ["detail-cap.jpg", "Detail — Cap", "The cap and the top of the shade."]
  ]
  ensure_images_section = lambda do |kit_recording|
    next unless defined?(RecordingStudioAttachable)

    existing = RecordingStudioPresskits::KitQuery.sections_for(kit_recording).find do |section|
      RecordingStudioPresskits::KitQuery.section_content(section)&.recordable.is_a?(RecordingStudioPresskits::Images)
    end
    brand = RecordingStudioPresskits::Cover::Company.name_for(kit_recording).presence || "Harbour Studio"
    subtitle = RecordingStudioPresskits::ImagesCredit.line_for(brand)
    section = existing || RecordingStudioPresskits.create_section!(
      press_kit_recording: kit_recording,
      content_type: "RecordingStudioPresskits::Images",
      actor: user,
      title: "Images",
      subtitle: subtitle
    )
    if existing && (existing.recordable.title != "Images" || existing.recordable.subtitle != subtitle)
      root_recording.revise(existing, actor: user) do |recordable|
        recordable.title = "Images"
        recordable.subtitle = subtitle
      end
      section = existing.reload
    end
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    RecordingStudioPresskits::DirectImages.list(content).each do |photo|
      next unless photo.recordable.original_filename == "harbour-gallery.jpg"

      photo.recording_studio_trashable_trash!(actor: user)
    end
    press_image_seeds.each do |filename, name, alt|
      path = Rails.root.join("db/seed_images/press", filename)
      next unless path.file?

      already = RecordingStudioPresskits::DirectImages.list(content).find do |photo|
        photo.recordable.original_filename == filename
      end
      if already
        RecordingStudioPresskits::ImagePixelSize.ensure_blob!(already.recordable.file.blob)
        next
      end

      photo = File.open(path, "rb") do |io|
        content.import_attachment(
          io: io,
          filename: filename,
          content_type: "image/jpeg",
          name: name,
          actor: user,
          source: "press_photos"
        )
      end
      next if photo.blank?

      photo.revise_attachment_metadata(actor: user, alt_text: alt)
      content.recording_studio_orderable_append!(photo, actor: user)
      RecordingStudioPresskits::ImagePixelSize.ensure_blob!(photo.recordable.file.blob)
    end
  end
  ensure_images_section.call(press_kit_recording)

  ensure_stats_section = lambda do |kit_recording, title, stats|
    existing = RecordingStudioPresskits::KitQuery.sections_for(kit_recording).find do |section|
      section.recordable.title == title
    end
    section = existing || RecordingStudioPresskits.create_section!(
      press_kit_recording: kit_recording,
      content_type: "RecordingStudioPresskits::StatsSection",
      actor: user,
      title: title
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    stats.each do |label, value, unit, icon|
      existing = RecordingStudioPresskits::StatsSection.active_stats(content).find do |child|
        child.recordable.label == label && child.recordable.value == value
      end
      if existing
        next if existing.recordable.icon == icon

        root_recording.revise(existing, actor: user) do |stat|
          stat.icon = icon
        end
        next
      end

      content.record(RecordingStudioPresskits::Stat, parent_recording: content, actor: user) do |stat|
        stat.label = label
        stat.value = value
        stat.unit = unit
        stat.icon = icon
      end
    end
  end

  ensure_stats_section.call(
    press_kit_recording,
    "Company statistics",
    [
      ["Projects", "120", nil, "chart-bar"],
      ["Countries", "15", nil, "globe-alt"],
      ["Employees", "85", nil, "users"]
    ]
  )
  ensure_stats_section.call(
    press_kit_recording,
    "Project specifications",
    [
      ["Floor area", "420", "m²", "building-office-2"],
      ["Completion", "2025", nil, "calendar-days"],
      ["Project cost", "2.4 million", "AUD", "currency-dollar"]
    ]
  )

  ensure_location_section = lambda do |kit_recording, title, places|
    existing = RecordingStudioPresskits::KitQuery.sections_for(kit_recording).find do |section|
      section.recordable.title == title
    end
    section = existing || RecordingStudioPresskits.create_section!(
      press_kit_recording: kit_recording,
      content_type: "RecordingStudioPresskits::LocationSection",
      actor: user,
      title: title
    )
    content = RecordingStudioPresskits::KitQuery.section_content(section)
    places.each do |attributes|
      already = RecordingStudioPresskits::LocationSection.active_locations(content).any? do |child|
        child.recordable.title == attributes[:title]
      end
      next if already

      content.record(RecordingStudio::Location::Location, parent_recording: content, actor: user) do |location|
        location.assign_attributes(attributes)
      end
    end
  end

  ensure_location_section.call(
    press_kit_recording,
    "Where to find us",
    [
      {
        title: "The Pavilion",
        location_type: "venue",
        name: "The Pavilion",
        locality: "Melbourne",
        region: "Victoria",
        country_code: "AU"
      }
    ]
  )

  ensure_kit_description = lambda do |kit_recording, description|
    recordable = kit_recording.recordable
    return if recordable.description == description

    root_recording.revise(kit_recording, actor: user) do |press_kit|
      press_kit.description = description
    end
    kit_recording.reload
  end

  ensure_visibility_kit = lambda do |title, description:, audience:, fallback:, slug:|
    kit = find_or_record_named_child.call(
      RecordingStudioPresskits::PressKit,
      title,
      root_recording,
      root_recording,
      description: description
    )
    ensure_kit_description.call(kit, description)
    publish_kit.call(kit, slug: slug, status: "published")
    RecordingStudioPresskits::Visibility.set_audience!(
      recording: kit,
      audience: audience,
      actor: user
    )
    RecordingStudioPresskits::KitSettings.save_fallback!(
      recording: kit,
      fallback: fallback,
      actor: user
    )
    kit.reload
  end

  ensure_visibility_kit.call(
    "Members only launch",
    description: "A kit for people who have an account.",
    audience: :signed_in,
    fallback: :preview,
    slug: "members-only-launch"
  )
  ensure_visibility_kit.call(
    "Invite only launch",
    description: "A kit for invited guests.",
    audience: :granted,
    fallback: :preview,
    slug: "invite-only-launch"
  )
  ensure_visibility_kit.call(
    "Quiet launch",
    description: "This stays off the public list.",
    audience: :granted,
    fallback: :hidden,
    slug: "quiet-launch"
  )

  acme = Showcase.find_or_create_by!(name: "ACME desk")
  acme_recording = find_or_record_child.call(acme, root_recording, root_recording)
  spring_film = find_or_record_named_child.call(
    RecordingStudioPresskits::PressKit,
    "Spring film",
    root_recording,
    acme_recording,
    description: "Logos, bios, and the spring film.",
    subtitle: "From the ACME desk"
  )
  house_style = find_or_record_named_child.call(
    RecordingStudioPresskits::PressKit,
    "House style",
    root_recording,
    acme_recording,
    description: "This kit picks its own colour and font.",
    subtitle: "Not the desk",
    brand_color: "#DB2777",
    font_family: "mono"
  )
  if house_style.recordable.brand_color != "#DB2777" || house_style.recordable.font_family != "mono"
    root_recording.revise(house_style, actor: user) do |press_kit|
      press_kit.brand_color = "#DB2777"
      press_kit.font_family = "mono"
    end
  end
  publish_kit.call(spring_film, slug: "spring-film", status: "published")
  publish_kit.call(house_style, slug: "house-style", status: "published")

  [root_recording, accessible_root_recording, private_root_recording, admin_root_recording].each do |recording|
    bootstrap_owner_access.call(recording, user)
  end
ensure
  Current.actor = previous_actor
end

puts "Seeded: admin@admin.com / Password"
puts "Seeded: Workspace '#{workspace.name}' with root recording ##{root_recording.id}"
puts "Seeded: Workspace '#{accessible_workspace.name}' with root recording ##{accessible_root_recording.id}"
puts "Seeded: Workspace '#{private_workspace.name}' with root recording ##{private_root_recording.id}"
puts "Seeded: Admin root '#{admin_root.name}' with root recording ##{admin_root_recording.id}"
puts "Seeded: Folder '#{folder.name}' and page '#{page.title}'"
puts "Seeded: Press kit 'Spring launch' published at /published/:uuid/spring-launch"
puts "Seeded: Press kit 'Autumn recap' as unpublished"
puts "Seeded: Press kit 'Members only launch' signed_in preview at /published/:uuid/members-only-launch"
puts "Seeded: Press kit 'Invite only launch' granted preview at /published/:uuid/invite-only-launch"
puts "Seeded: Press kit 'Quiet launch' granted hidden at /published/:uuid/quiet-launch"
