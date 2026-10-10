import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  browse(event) {
    event.preventDefault()
    event.currentTarget.closest("form")?.querySelector("input[type=file]")?.click()
  }
}
