import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static classes = ["active", "inactive"]

  select(event) {
    const index = Number(event.params.index)

    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index)
    })

    this.tabTargets.forEach((tab, i) => {
      const active = i === index
      tab.classList.remove(...(active ? this.inactiveClasses : this.activeClasses))
      tab.classList.add(...(active ? this.activeClasses : this.inactiveClasses))
    })
  }
}
