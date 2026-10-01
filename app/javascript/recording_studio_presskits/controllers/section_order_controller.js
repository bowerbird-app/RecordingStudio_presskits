import { Controller } from "@hotwired/stimulus"

// FlatPack list-orderable owns the drag. This pin's saveOrder checks
// hasOrderablePathValue, and that value is not defined, so the fetch never runs.
// list:reordered still fires. This posts the new neighbor to Orderable.
export default class extends Controller {
  static values = { url: String }

  save(event) {
    if (this.submitted || !this.hasUrlValue) return

    const recordingId = event.detail?.id
    if (!recordingId) return

    const items = [...this.element.querySelectorAll("li[role='listitem']")]
    const index = items.findIndex((item) => item.id === recordingId || item.dataset.id === recordingId)
    if (index < 0) return

    const fields = { recording_id: recordingId }
    const next = items[index + 1]
    const previous = items[index - 1]
    if (next) fields.before_recording_id = next.id || next.dataset.id
    else if (previous) fields.after_recording_id = previous.id || previous.dataset.id

    this.submit(fields)
  }

  submit(fields) {
    if (!fields.recording_id) return

    this.submitted = true
    const form = document.createElement("form")
    form.method = "post"
    form.action = this.urlValue

    const token = document.querySelector("meta[name='csrf-token']")?.getAttribute("content") || ""
    const payload = {
      _method: "patch",
      authenticity_token: token,
      ...fields
    }

    Object.entries(payload).forEach(([name, value]) => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = name
      input.value = value
      form.appendChild(input)
    })

    document.body.appendChild(form)
    form.submit()
  }
}
