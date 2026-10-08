import { Controller } from "@hotwired/stimulus"

// A saved drag keeps the kit preview in the same order as the rows.
export default class extends Controller {
  sync(event) {
    const preview = document.querySelector("#presskits-section-preview [data-credit-lines]")
    const list = this.listElement(event)
    if (!preview || !list) return

    this.savedIds(list).forEach((id) => {
      const line = preview.querySelector(`[data-credit-line-id="${CSS.escape(id)}"]`)
      if (line) preview.appendChild(line)
    })
  }

  listElement(event) {
    const target = event.target
    if (target instanceof Element && target.matches("ul")) return target

    return this.element.querySelector("ul.flat-pack-collection-editor-rows")
  }

  savedIds(list) {
    return [...list.querySelectorAll("li[role='listitem']")]
      .filter((row) => row.dataset.orderableUnsaved !== "true")
      .filter((row) => row.dataset.collectionEditorDestroyed !== "true")
      .map((row) => row.dataset.id)
      .filter(Boolean)
  }
}
