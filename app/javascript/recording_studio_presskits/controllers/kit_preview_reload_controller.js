import { Controller } from "@hotwired/stimulus"

// Flatpack list-orderable saves over fetch. Reload the kit so the preview
// behind the Reorder modal matches the Orderable positions.
export default class extends Controller {
  reload() {
    const turbo = window.Turbo
    if (turbo?.visit) {
      turbo.visit(window.location.href, { action: "replace" })
      return
    }

    window.location.reload()
  }
}
