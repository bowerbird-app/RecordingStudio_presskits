import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { credits: Array }
  static targets = ["chosen", "chosenName", "existingRole", "usualRole", "newRole"]

  connect() {
    this.roleTouched = this.kitRoleDiffers()
    this.showChosen(this.selectedId())
  }

  choose(event) {
    if (event.target?.name !== "credit_id") return

    this.showChosen(event.target.value)
  }

  copyUsualRole(event) {
    if (this.roleTouched || !this.hasNewRoleTarget) return
    if (event.target?.name !== "credit[usual_role]") return

    this.roleInput(this.newRoleTarget).value = event.target.value
  }

  touchKitRole(event) {
    if (event.target?.name !== "role") return
    if (!this.hasNewRoleTarget || !this.newRoleTarget.contains(event.target)) return

    this.roleTouched = true
  }

  showChosen(id) {
    if (!this.hasChosenTarget) return

    const credit = this.creditsValue.find((item) => item.id === id)
    if (!credit) {
      this.chosenTarget.hidden = true
      return
    }

    this.chosenNameTarget.textContent = credit.name
    this.roleInput(this.existingRoleTarget).value = credit.usual_role || ""
    this.chosenTarget.hidden = false
  }

  selectedId() {
    return this.element.querySelector("input[name='credit_id']")?.value || ""
  }

  kitRoleDiffers() {
    if (!this.hasNewRoleTarget || !this.hasUsualRoleTarget) return false

    const role = this.roleInput(this.newRoleTarget).value
    return role !== "" && role !== this.roleInput(this.usualRoleTarget).value
  }

  roleInput(wrapper) {
    return wrapper.querySelector("input")
  }
}
