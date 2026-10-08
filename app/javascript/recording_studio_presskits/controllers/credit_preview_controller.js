import { Controller } from "@hotwired/stimulus"

// The preview column follows the credit rows while the form is still open.
export default class extends Controller {
  connect() {
    this.catalog = this.readCatalog()
  }

  sync(event) {
    const lines = this.previewLines()
    const list = this.listElement(event)
    if (!lines || !list) return

    this.rowIds(list).forEach((id) => {
      const line = this.previewLine(id)
      if (line) lines.append(line)
    })
  }

  choose(event) {
    const row = event.target?.closest?.("[data-collection-editor-row]")
    const name = event.detail?.title?.trim() || ""
    const creditId = String(event.detail?.id || "")
    if (!row || !name || !creditId) return

    if (event.detail?.description) row.dataset.usualRole = event.detail.description

    const line = this.ensureLine(row.dataset.id)
    if (!line) return

    this.setName(line, name, this.urlFor(creditId, row))
    this.setRole(line, this.shownRole(row))
    this.sync({target: row.closest("ul")})
  }

  role(event) {
    const input = event.target
    if (!(input instanceof HTMLInputElement) && !(input instanceof HTMLTextAreaElement)) return
    if (!input.name?.includes("[role]")) return

    const row = input.closest("[data-collection-editor-row]")
    if (!row || row.hidden || row.dataset.collectionEditorDestroyed === "true") return

    const line = this.previewLine(row.dataset.id)
    if (!line) return

    this.setRole(line, this.shownRole(row))
  }

  drop(event) {
    const target = event.target
    if (!(target instanceof Element)) return

    const button = target.closest("[data-collection-editor-remove], [data-collection-editor-chip-remove]")
    if (!button) return

    const id = button.closest("[data-collection-editor-row]")?.dataset.id
    this.previewLine(id)?.remove()
  }

  readCatalog() {
    const node = this.element.querySelector("[data-credit-catalog]")
    if (!node) return {}

    try {
      const parsed = JSON.parse(node.textContent)
      return parsed && typeof parsed === "object" ? parsed : {}
    } catch (_error) {
      return {}
    }
  }

  urlFor(creditId, row) {
    if (Object.prototype.hasOwnProperty.call(this.catalog, creditId)) {
      return this.safeUrl(this.catalog[creditId])
    }

    const url = this.safeUrl(this.createdUrl(row))
    this.catalog[creditId] = url
    return url
  }

  createdUrl(row) {
    const modalId = row.querySelector("[data-create-modal-id]")?.getAttribute("data-create-modal-id")
    const modal = modalId ? document.getElementById(modalId) : null
    return (modal || row).querySelector("[data-create-field='url']")?.value?.trim() || ""
  }

  shownRole(row) {
    const typed = row.querySelector("input[name*='[role]'], textarea[name*='[role]']")?.value?.trim() || ""
    if (typed) return typed
    if (row.dataset.orderableUnsaved === "true") return row.dataset.usualRole?.trim() || ""

    return ""
  }

  ensureLine(id) {
    if (!id) return null

    const existing = this.previewLine(id)
    if (existing) return existing

    const lines = this.previewLines()
    if (!lines) return null

    const line = document.createElement("div")
    line.dataset.creditLineId = id
    lines.append(line)
    return line
  }

  setRole(line, role) {
    let node = line.querySelector("[data-credit-role]")
    if (!role) {
      node?.remove()
      return
    }

    if (!node) {
      node = document.createElement("p")
      node.className = "text-sm text-(--surface-muted-content-color)"
      node.dataset.creditRole = "true"
      line.prepend(node)
    }

    node.textContent = role
  }

  setName(line, name, url) {
    let node = line.querySelector("[data-credit-name]")
    if (!node) {
      node = document.createElement("p")
      node.className = "text-base text-(--surface-content-color)"
      node.dataset.creditName = "true"
      line.append(node)
    }

    node.replaceChildren()
    const safe = this.safeUrl(url)
    if (!safe) {
      node.textContent = name
      return
    }

    const link = document.createElement("a")
    link.href = safe
    link.target = "_blank"
    link.rel = "noopener noreferrer"
    link.textContent = name
    node.append(link)
  }

  previewLine(id) {
    if (!id) return null

    return this.previewLines()?.querySelector(`[data-credit-line-id="${CSS.escape(id)}"]`) || null
  }

  previewLines() {
    const preview = document.querySelector("#presskits-section-preview")
    if (!preview) return null

    const existing = preview.querySelector("[data-credit-lines]")
    if (existing) return existing

    const lines = document.createElement("div")
    lines.className = "flex flex-col gap-5"
    lines.setAttribute("data-credit-lines", "")

    const card = preview.firstElementChild
    if (card) {
      card.append(lines)
      return lines
    }

    const shell = document.createElement("div")
    shell.className = "w-full rounded-[var(--radius-lg)] bg-[var(--card-background-color)] border border-[var(--card-border-color)] text-[var(--surface-content-color)] p-6"
    shell.append(lines)
    preview.append(shell)
    return lines
  }

  listElement(event) {
    const target = event.target
    if (target instanceof Element && target.matches("ul")) return target

    return this.element.querySelector("ul.flat-pack-collection-editor-rows")
  }

  rowIds(list) {
    return [...list.querySelectorAll("li[role='listitem']")]
      .filter((row) => row.dataset.collectionEditorDestroyed !== "true")
      .filter((row) => !row.hidden)
      .map((row) => row.dataset.id)
      .filter(Boolean)
  }

  safeUrl(url) {
    const value = String(url || "").trim()
    if (!value || /&(?:colon|#(?:0*58|x0*3a));/i.test(value)) return ""
    if (/^\s*(javascript|data|vbscript):/i.test(value)) return ""
    if (value.startsWith("/") || value.startsWith(".") || value.startsWith("#")) return value

    const match = value.match(/^([a-z][a-z0-9+.-]*):/i)
    if (!match) return value.includes(":") ? "" : value

    return ["http", "https", "mailto", "tel"].includes(match[1].toLowerCase()) ? value : ""
  }
}
