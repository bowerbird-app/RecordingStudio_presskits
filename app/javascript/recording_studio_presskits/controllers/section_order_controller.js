import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]
  static values = { url: String }

  connect() {
    this.draggedItem = null
    this.itemTargets.forEach((item) => {
      const handle = item.querySelector("[data-flat-pack--icon-name-value='arrows-up-down']")
      if (!handle) return

      const grip = handle.closest("span") || handle
      grip.draggable = true
      grip.style.cursor = "grab"
      grip.addEventListener("dragstart", (event) => this.start(event, item))
      grip.addEventListener("dragend", () => this.end())
      item.addEventListener("dragover", (event) => event.preventDefault())
      item.addEventListener("drop", (event) => this.drop(event, item))
    })
  }

  start(event, item) {
    this.draggedItem = item
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", item.dataset.recordingId || "")
    item.style.opacity = "0.7"
  }

  end() {
    const item = this.draggedItem
    requestAnimationFrame(() => {
      if (item) item.style.opacity = ""
      if (this.draggedItem === item) this.draggedItem = null
    })
  }

  drop(event, target) {
    event.preventDefault()
    const dragged = this.draggedItem
    if (!dragged || dragged === target || this.submitted) return

    const from = this.itemTargets.indexOf(dragged)
    const to = this.itemTargets.indexOf(target)
    if (from < 0 || to < 0) return

    if (from < to) this.element.insertBefore(dragged, target.nextSibling)
    else this.element.insertBefore(dragged, target)

    const fields = { recording_id: dragged.dataset.recordingId }
    if (from < to) fields.after_recording_id = target.dataset.recordingId
    else fields.before_recording_id = target.dataset.recordingId
    this.submit(fields)
  }

  submit(fields) {
    if (!fields.recording_id || !this.hasUrlValue) return

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
